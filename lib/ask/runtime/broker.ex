defmodule Ask.Runtime.Broker do
  use Timex
  import Ecto.Query
  import Ecto
  alias Ask.{Repo, Respondent, RespondentDispositionHistory, QuotaBucket, Logger, SystemTime}
  alias Ask.Runtime.{Session, Reply, Flow, SessionMode, SessionModeProvider, RetriesHistogram}

  def sync_step(respondent, reply, mode \\ nil, now \\ SystemTime.time.now) do
    session = respondent.session |> Session.load
    session_mode = session_mode(respondent, session, mode)
    next_action = sync_step_internal(session, reply, session_mode, now)
    handle_next_action(next_action, respondent.id)
  end

  defp handle_next_action(next_action, respondent_id) do
    respondent = Repo.get(Respondent, respondent_id)
    session = if respondent.session, do: Session.load(respondent.session), else: respondent.session
    RetriesHistogram.next_step(respondent, session, next_action)
    next_action
  end

  # We expose this method so we can test that if a stale respondent is
  # passed, it's reloaded and the action is retried (this can happen
  # if a timeout happens in between this call)
  def sync_step_internal(session, reply) do
    sync_step_internal(session, reply, session.current_mode, SystemTime.time.now)
  end

  def sync_step_internal(_, _, :invalid_mode, _) do
    :end
  end

  def sync_step_internal(session, reply, session_mode, now) do
    transaction_result = Repo.transaction(fn ->
      try do
        reply = mask_phone_number(session.respondent, reply)
        session_step = Session.sync_step(session, reply, session_mode)
        handle_session_step(session_step, now)
      rescue
        e in Ecto.StaleEntryError ->
          Repo.rollback(e)
        e ->
          # If we uncomment this a test will fail (the one that cheks that nothing breaks),
          # but this could help you find a bug in a particular test that is not working.
          # if Mix.env == :test do
          #   IO.inspect e
          #   IO.inspect System.stacktrace()
          #   raise e
          # end
          respondent = Repo.get(Respondent, session.respondent.id)
          Logger.error(e, "Error occurred while processing sync step (survey_id: #{respondent.survey_id}, respondent_id: #{respondent.id})")
          Sentry.capture_exception(e, [
            stacktrace: System.stacktrace(),
            extra: %{survey_id: respondent.survey_id, respondent_id: respondent.id}])

          try do
            handle_session_step({:failed, respondent}, now)
          rescue
            e ->
              if Mix.env == :test do
                IO.inspect e
                IO.inspect System.stacktrace()
                raise e
              end
              :end
          end
      end
    end)

    case transaction_result do
      {:ok, response} ->
        response
      {:error, %Ecto.StaleEntryError{}} ->
        respondent = Repo.get(Respondent, session.respondent.id)
        # Maybe timeout or another action was executed while sync_step was executed, so we need to retry
        sync_step(respondent, reply, session_mode)
      value ->
        value
    end
  end

  def mask_phone_number(%Respondent{} = respondent, {:reply, response}) do
    pii = respondent.canonical_phone_number |> String.slice(-6..-1)
    # pii can be empty if the sanitized_phone_number has less than 5 digits,
    # that could be mostly to the case of a randomly generated phone number form a test
    # String.contains? returns true for empty strings
    masked_response = if String.length(pii) != 0 && contains_phone_number(response, pii) do
      mask_phone_number(response, phone_number_matcher(pii), pii)
    else
      response
    end

    Flow.Message.reply(masked_response)
  end
  def mask_phone_number(_, reply), do: reply
  def mask_phone_number(response, regex, pii) do
    masked_response = response |> String.replace(regex, "\\1#\\3#\\5#\\7#\\9#\\11#\\13")

    if contains_phone_number(masked_response, pii) do
      mask_phone_number(masked_response, regex, pii)
    else
      masked_response
    end
  end

  def handle_session_step({:ok, %{respondent: respondent} = session, reply, timeout}, now) do
    update_respondent(respondent, {:ok, session, timeout}, Reply.disposition(reply), now)
    {:reply, reply}
  end

  def handle_session_step({:hangup, session, reply, timeout, respondent}, _) do
    update_respondent(respondent, {:ok, session, timeout}, Reply.disposition(reply), SystemTime.time.now)
    :end
  end

  def handle_session_step({:end, reply, respondent}, _) do
    update_respondent(respondent, :end, Reply.disposition(reply), nil)

    case Reply.steps(reply) do
      [] ->
        :end
      _ ->
        {:end, {:reply, reply}}
    end
  end

  def handle_session_step({:rejected, reply, respondent}, _) do
    update_respondent(respondent, :rejected)
    {:end, {:reply, reply}}
  end

  def handle_session_step({:rejected, %{respondent: respondent} = session, reply, timeout}, _) do
    update_respondent(respondent, {:rejected, session, timeout})
    {:reply, reply}
  end

  def handle_session_step({:rejected, respondent}, _) do
    update_respondent(respondent, :rejected)
    :end
  end

  def handle_session_step({:stalled, session, respondent}, _) do
    update_respondent(respondent, {:stalled, session})
  end

  def handle_session_step({:stopped, reply, respondent}, _) do
    update_respondent(respondent, :stopped, Reply.disposition(reply), nil)
    :end
  end

  def handle_session_step({:failed, respondent}, _) do
    update_respondent(respondent, :failed)
    :end
  end

  def update_respondent(%Respondent{} = respondent, :end) do
    update_respondent(respondent, :end, nil, nil)
  end

  def update_respondent(%Respondent{} = respondent, {:stalled, session}) do
    respondent
    |> Respondent.changeset(%{state: "stalled", session: Session.dump(session), timeout_at: nil})
    |> Repo.update!
  end

  def update_respondent(%Respondent{} = respondent, :rejected) do
    respondent
    |> Respondent.changeset(%{state: "rejected", session: nil, timeout_at: nil})
    |> Repo.update!
  end

  def update_respondent(%Respondent{} = respondent, {:rejected, session, timeout}) do
    timeout_at = Respondent.next_actual_timeout(respondent, timeout, SystemTime.time.now)
    respondent
      |> Respondent.changeset(%{state: "rejected", session: Session.dump(session), timeout_at: timeout_at})
      |> Repo.update!
  end

  def update_respondent(%Respondent{} = respondent, :failed) do
    session = respondent.session |> Session.load
    mode = session.current_mode |> SessionMode.mode
    old_disposition = respondent.disposition
    new_disposition = Flow.failed_disposition_from(respondent.disposition)

    Session.log_disposition_changed(respondent, session.current_mode.channel, mode, old_disposition, new_disposition)

    respondent
    |> Respondent.changeset(%{state: "failed", session: nil, timeout_at: nil, disposition: new_disposition})
    |> Repo.update!
    |> RespondentDispositionHistory.create(old_disposition, mode)
  end

  def update_respondent(%Respondent{} = respondent, :stopped, disposition, _) do
    session = respondent.session |> Session.load
    update_respondent_and_set_disposition(respondent, session, nil, %{disposition: disposition, state: "failed", session: nil, timeout_at: nil, user_stopped: true})
  end

  def update_respondent(%Respondent{} = respondent, {:ok, session, timeout}, nil, now) do
    effective_modes = respondent.effective_modes || []
    effective_modes =
      if session do
        mode = Ask.Runtime.SessionMode.mode(session.current_mode)
        Enum.uniq(effective_modes ++ [mode])
      else
        effective_modes
      end

    timeout_at = Respondent.next_actual_timeout(respondent, timeout, now)
    respondent
    |> Respondent.changeset(%{state: "active", session: Session.dump(session), timeout_at: timeout_at, language: session.flow.language, effective_modes: effective_modes})
    |> Repo.update!
  end

  def update_respondent(%Respondent{} = respondent, {:ok, session, timeout}, disposition, _) do
    timeout_at = Respondent.next_actual_timeout(respondent, timeout, SystemTime.time.now)
    update_respondent_and_set_disposition(respondent, session, timeout, %{session: Session.dump(session), timeout_at: timeout_at, disposition: disposition, state: "active"})
  end

  def update_respondent(%Respondent{} = respondent, :end, reply_disposition, _) do
    [session, mode] = case respondent.session do
      nil -> [nil, nil]
      session ->
        session = session |> Session.load
        mode = session.current_mode |> SessionMode.mode
        [session, mode]
    end

    old_disposition = respondent.disposition

    new_disposition =
      old_disposition
      |> Flow.resulting_disposition(reply_disposition)
      |> Flow.resulting_disposition("completed")

    # If new_disposition == reply_disposition, change of disposition has already been logged during Session.sync_step
    if session && new_disposition != old_disposition && new_disposition != reply_disposition do
      Session.log_disposition_changed(respondent, session.current_mode.channel, mode, old_disposition, new_disposition)
    end

    respondent
    |> Respondent.changeset(%{state: "completed", disposition: new_disposition, session: nil, completed_at: SystemTime.time.now, timeout_at: nil})
    |> Repo.update!
    |> RespondentDispositionHistory.create(old_disposition, mode)
    |> update_quota_bucket(old_disposition, respondent.session["count_partial_results"])
  end

  def channel_failed(respondent, reason \\ "failed") do
    session = respondent.session
    if session do
      session = session |> Session.load
      case Session.channel_failed(session, reason) do
        :ok -> :ok
        :failed ->
          # respondent no longer participates in the survey (no attempts left)
          respondent = RetriesHistogram.remove_respondent(respondent)
          update_respondent(respondent, :failed)
      end
    else
      :ok
    end
  end

  def contact_attempt_expired(respondent) do
    session = respondent.session
    if session do
      response = session
                 |> Session.load
                 |> Session.contact_attempt_expired

      update_respondent(respondent, response, nil, SystemTime.time.now)
    end
    :ok
  end

  def delivery_confirm(respondent, title) do
    delivery_confirm(respondent, title, nil)
  end

  def delivery_confirm(respondent, title, mode) do
    unless respondent.session == nil do
      session = respondent.session |> Session.load
      session_mode =
        case session_mode(respondent, session, mode) do
          :invalid_mode -> session.current_mode
          mode -> mode
        end
      Session.delivery_confirm(session, title, session_mode)
    end
  end

  defp session_mode(_respondent, session, nil) do
    session.current_mode
  end

  defp session_mode(respondent, session, mode) do
    if mode == session.current_mode |> SessionMode.mode do
      session.current_mode
    else
      group = (respondent |> Repo.preload(:respondent_group)).respondent_group
      channel_group = (group |> Repo.preload([respondent_group_channels: :channel])).respondent_group_channels
                      |> Enum.find(fn c -> c.mode == mode end)

      if channel_group do
        SessionModeProvider.new(mode, channel_group.channel, [])
      else
        :invalid_mode
      end
    end
  end

  defp update_respondent_and_set_disposition(respondent, session, timeout, %{disposition: disposition} =  changes) do
    old_disposition = respondent.disposition
    if Flow.should_update_disposition(old_disposition, disposition) do
      respondent
      |> Respondent.changeset(changes)
      |> Repo.update!
      |> RespondentDispositionHistory.create(old_disposition, session.current_mode |> SessionMode.mode)
      |> update_quota_bucket(old_disposition, session.count_partial_results)
    else
      update_respondent(respondent, {:ok, session, timeout}, nil, SystemTime.time.now)
    end
  end

  defp update_quota_bucket(respondent, old_disposition, count_partial_results) do
    if should_update_quota_bucket(respondent.disposition, old_disposition, count_partial_results) do
      responses = respondent |> assoc(:responses) |> Repo.all
      matching_bucket = Repo.all(from b in QuotaBucket, where: b.survey_id == ^respondent.survey_id)
                      |> Enum.find( fn bucket -> match_condition(responses, bucket) end )

      if matching_bucket do
        from(q in QuotaBucket, where: q.id == ^matching_bucket.id) |> Ask.Repo.update_all(inc: [count: 1])
      end
    end
    respondent
  end

  defp should_update_quota_bucket(new_disposition, old_disposition, true) do
    (new_disposition != old_disposition && new_disposition == "interim partial")
    || (new_disposition == "completed" && old_disposition != "interim partial" && old_disposition != "completed")
  end

  defp should_update_quota_bucket(new_disposition, old_disposition, _) do
    new_disposition != old_disposition && new_disposition == "completed"
  end

  defp match_condition(responses, bucket) do
    bucket_vars = Map.keys(bucket.condition)

    Enum.all?(bucket_vars, fn var ->
      Enum.any?(responses, fn res ->
        (res.field_name == var) &&
          res.value |> QuotaBucket.matches_condition?(Map.fetch!(bucket.condition, var))
      end)
    end)
  end

  defp contains_phone_number(response, pii) do
    String.contains?(Respondent.canonicalize_phone_number(response), pii)
  end

  defp phone_number_matcher(pii) do
    String.graphemes(pii)
    |> Enum.reduce("(.*)", fn(digit, regex) ->
      "#{regex}(#{digit})(.*)"
    end)
    |> Regex.compile!
  end

end
