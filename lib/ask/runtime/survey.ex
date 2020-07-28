defmodule Ask.Runtime.Survey do
  use Timex
  import Ecto.Query
  import Ecto
  alias Ask.{Repo, Respondent, RespondentDispositionHistory, QuotaBucket, Logger, SystemTime}
  alias Ask.Runtime.{Session, Reply, Flow, SessionMode, SessionModeProvider, RetriesHistogram}

  def sync_step(respondent, reply, mode \\ nil, now \\ SystemTime.time.now, persist \\ true) do
    session = Session.load_respondent_session(respondent, persist)
    session_mode = session_mode(respondent, session, mode)
    next_action = sync_step_internal(session, reply, session_mode, now, persist)
    handle_next_action(next_action, respondent.id, persist)
  end

  # We expose this method so we can test that if a stale respondent is
  # passed, it's reloaded and the action is retried (this can happen
  # if a timeout happens in between this call)
  def sync_step_internal(session, reply, persist \\ true) do
    sync_step_internal(session, reply, session.current_mode, SystemTime.time.now, persist)
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

  @doc """
  Performs all updates and changes according the given session_step
  Indicates weather:
    - the session is still active and reply must be given to the respondent
    - the session ends with the current step, but a last reply must be given to the respondent
    - the session ends with the current step

  Respondent is returned so that there is visibility of the changes that were made to it

  Possible return patterns:
    - {:reply, reply, respondent}
    - {:end, reply, respondent}
    - {:end, respondent}
  """
  def handle_session_step(session_step, now, persist \\ true)

  def handle_session_step({:ok, %{respondent: respondent} = session, reply, timeout}, now, persist) do
    timeout_at = Respondent.next_actual_timeout(respondent, timeout, now, persist)
    updated_respondent = respondent_updates(:ok, respondent, session, Reply.disposition(reply), timeout_at, persist)
    updated_respondent = if(disposition_changed?(respondent, updated_respondent)) do
      disposition_changed(updated_respondent, session, respondent.disposition, persist)
    else
      updated_respondent
    end
    {:reply, reply, updated_respondent}
  end

  def handle_session_step({:hangup, session, reply, timeout, respondent}, _, persist) do
    timeout_at = Respondent.next_actual_timeout(respondent, timeout, SystemTime.time.now, persist)
    updated_respondent = respondent_updates(:ok, respondent, session, Reply.disposition(reply), timeout_at, persist)
    updated_respondent = if(disposition_changed?(respondent, updated_respondent)) do
      disposition_changed(updated_respondent, session, respondent.disposition, persist)
    else
      updated_respondent
    end
    {:end, updated_respondent}
  end

  def handle_session_step({:end, reply, respondent}, _, persist) do
    session = case respondent.session do
      nil -> nil
      _ -> Session.load_respondent_session(respondent, persist)
    end

    old_disposition = respondent.disposition
    reply_disposition = Reply.disposition(reply)

    new_disposition = old_disposition
                      |> Flow.resulting_disposition(reply_disposition)
                      |> Flow.resulting_disposition("completed")

    updated_respondent = respondent_updates(:end, respondent, new_disposition, persist)
                         |> disposition_changed(session, old_disposition, persist)

    # If new_disposition == reply_disposition, change of disposition has already been logged during Session.sync_step
    if persist && session && new_disposition != old_disposition && new_disposition != reply_disposition do
      mode = session.current_mode |> SessionMode.mode
      Session.log_disposition_changed(updated_respondent, session.current_mode.channel, mode, old_disposition, new_disposition, persist)
    end

    case Reply.steps(reply) do
      [] ->
        {:end, updated_respondent}
      _ ->
        {:end, {:reply, reply}, updated_respondent}
    end
  end

  def handle_session_step({:rejected, reply, respondent}, _, persist) do
    updated_respondent =respondent_updates(:rejected, respondent, nil, nil, persist)
    {:end, {:reply, reply}, updated_respondent}
  end

  def handle_session_step({:rejected, %{respondent: respondent} = session, reply, timeout}, _, persist) do
    timeout_at = Respondent.next_actual_timeout(respondent, timeout, SystemTime.time.now, persist)
    updated_respondent = respondent_updates(:rejected, respondent, session, timeout_at, persist)
    {:reply, reply, updated_respondent}
  end

  def handle_session_step({:rejected, respondent}, _, persist) do
    updated_respondent = respondent_updates(:rejected, respondent, nil, nil, persist)
    {:end, updated_respondent}
  end

  def handle_session_step({:stopped, reply, respondent}, _, persist) do
    updated_respondent = respondent_updates(:stopped, respondent, Reply.disposition(reply), persist)
    updated_respondent = if(disposition_changed?(respondent, updated_respondent)) do
      disposition_changed(updated_respondent, Session.load_respondent_session(respondent, persist), respondent.disposition, persist)
    else
      updated_respondent
    end
    {:end, updated_respondent}
  end

  def handle_session_step({:failed, respondent}, _, persist) do
    updated_respondent = failed_session(respondent, persist)
    {:end, updated_respondent}
  end

  def failed_session(respondent, persist) do
    session = Session.load_respondent_session(respondent, persist)
    mode = session.current_mode |> SessionMode.mode
    old_disposition = respondent.disposition
    new_disposition = Flow.failed_disposition_from(respondent.disposition)

    updated_respondent = respondent_updates(:failed, respondent, persist)
    Session.log_disposition_changed(updated_respondent, session.current_mode.channel, mode, old_disposition, new_disposition, persist)
    disposition_changed(updated_respondent, session, old_disposition, persist)
  end

  def channel_failed(respondent, reason \\ "failed", persist \\ true) do
    session = respondent.session
    if session do
      session = session |> Session.load
      case Session.channel_failed(session, reason) do
        :ok -> :ok
        :failed ->
          # respondent no longer participates in the survey (no attempts left)
          respondent = RetriesHistogram.remove_respondent(respondent)
          failed_session(respondent, persist)
      end
    else
      :ok
    end
  end

  def contact_attempt_expired(respondent, persist \\ true) do
    session = respondent.session
    if session do
      response = session
                 |> Session.load
                 |> Session.contact_attempt_expired

      {:ok, session, timeout} = response
      timeout_at = Respondent.next_actual_timeout(respondent, timeout, SystemTime.time.now, persist)
      respondent_updates(:no_disposition, respondent, session, timeout_at, persist)
    end
    :ok
  end

  def delivery_confirm(respondent, title) do
    delivery_confirm(respondent, title, nil)
  end

  def delivery_confirm(respondent, title, mode, persist \\ true) do
    unless respondent.session == nil do
      session = Session.load_respondent_session(respondent, persist)
      session_mode =
        case session_mode(respondent, session, mode) do
          :invalid_mode -> session.current_mode
          mode -> mode
        end
      Session.delivery_confirm(session, title, session_mode, persist)
    end
  end

  defp disposition_changed?(original_respondent, updated_respondent), do:
    original_respondent.disposition != updated_respondent.disposition

  defp disposition_changed(respondent, session, old_disposition, persist) do
    if(persist) do
      mode = if session && session.current_mode do session.current_mode |> SessionMode.mode else nil end
      respondent
      |> RespondentDispositionHistory.create(old_disposition, mode)
      if session do
        update_quota_bucket(respondent, old_disposition, session.count_partial_results)
      end
    else
      respondent
    end
  end

  defp respondent_updates(:failed, respondent, persist) do
    new_disposition = Flow.failed_disposition_from(respondent.disposition)
    changes = %{state: "failed", session: nil, timeout_at: nil, disposition: new_disposition}
    Respondent.update(respondent, changes, persist)
  end

  defp respondent_updates(:end, respondent, disposition, persist) do
    changes = %{state: "completed", disposition: disposition, session: nil, completed_at: SystemTime.time.now, timeout_at: nil}
    Respondent.update(respondent, changes, persist)
  end

  defp respondent_updates(:stopped, respondent, disposition, persist) do
    changes = %{disposition: disposition, state: "failed", session: nil, timeout_at: nil, user_stopped: true}
    Respondent.update(respondent, changes, persist)
  end

  defp respondent_updates(:rejected, respondent, session, timeout_at, persist) do
    session_dump = if session != nil && persist, do: Session.dump(session), else: session
    changes = %{state: "rejected", session: session_dump, timeout_at: timeout_at}
    Respondent.update(respondent, changes, persist)
  end

  defp respondent_updates(:no_disposition, respondent, session, timeout_at, persist) do
    changes = no_disposition_changes(respondent, session, timeout_at, persist)
    Respondent.update(respondent, changes, persist)
  end

  defp respondent_updates(:ok, respondent, session, disposition, timeout_at, persist) do
    if disposition do
      session_dump = if persist, do: Session.dump(session), else: session
      intended_changes = %{session: session_dump, timeout_at: timeout_at, disposition: disposition, state: "active"}
      changes = respondent_updates_with_disposition(respondent, session, timeout_at, intended_changes, persist)
      Respondent.update(respondent, changes, persist)
    else
      respondent_updates(:no_disposition, respondent, session, timeout_at, persist)
    end
  end

  defp no_disposition_changes(respondent, session, timeout_at, persist) do
    effective_modes = respondent.effective_modes || []
    effective_modes =
      if session do
        mode = Ask.Runtime.SessionMode.mode(session.current_mode)
        Enum.uniq(effective_modes ++ [mode])
      else
        effective_modes
      end
    session_dump = if persist, do: Session.dump(session), else: session
    %{state: "active", session: session_dump, timeout_at: timeout_at, language: session.flow.language, effective_modes: effective_modes}
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

  defp sync_step_internal(session, _, :invalid_mode, _, _) do
    {:end, session.respondent}
  end

  defp sync_step_internal(session, reply, session_mode, now, persist) do
    transaction_result = Repo.transaction(fn ->
      try do
        reply = mask_phone_number(session.respondent, reply)
        session_step = Session.sync_step(session, reply, session_mode, persist, persist) # if don't want to persist, makes no sense to log the response
        handle_session_step(session_step, now, persist)
      rescue
        e in Ecto.StaleEntryError ->
          Logger.error(e, "Error on sync step internal. Rolling back transaction")
          Repo.rollback(e)
        e ->
          # If we uncomment this a test will fail (the one that cheks that nothing breaks),
          # but this could help you find a bug in a particular test that is not working.
          # if Mix.env == :test do
          #   IO.inspect e
          #   IO.inspect System.stacktrace()
          #   raise e
          # end
          respondent = if persist, do: Repo.get(Respondent, session.respondent.id), else: session.respondent
          Logger.error(e, "Error occurred while processing sync step (survey_id: #{respondent.survey_id}, respondent_id: #{respondent.id})")
          Sentry.capture_exception(e, [
            stacktrace: System.stacktrace(),
            extra: %{survey_id: respondent.survey_id, respondent_id: respondent.id}])

          try do
            handle_session_step({:failed, respondent}, now, persist)
          rescue
            e ->
              if Mix.env == :test do
                IO.inspect e
                IO.inspect System.stacktrace()
                raise e
              end
              {:end, respondent}
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

  defp respondent_updates_with_disposition(respondent, session, timeout, %{disposition: disposition} =  changes, persist) do
    old_disposition = respondent.disposition
    if Flow.should_update_disposition(old_disposition, disposition) do
      changes
    else
      no_disposition_changes(respondent, session, timeout, persist)
    end
  end

  defp update_quota_bucket(respondent, old_disposition, count_partial_results) do
    if Respondent.transitions_to_completed_disposition?(
         old_disposition,
         respondent.disposition,
         count_partial_results
       ) do
      responses = respondent |> assoc(:responses) |> Repo.all()

      matching_bucket =
        Repo.all(from(b in QuotaBucket, where: b.survey_id == ^respondent.survey_id))
        |> Enum.find(fn bucket -> match_condition(responses, bucket) end)

      if matching_bucket do
        from(q in QuotaBucket, where: q.id == ^matching_bucket.id)
        |> Ask.Repo.update_all(inc: [count: 1])
      end
    end

    respondent
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

  defp handle_next_action(next_action, respondent_id, persist) do
    if persist do
      respondent = Repo.get(Respondent, respondent_id)
      session = if respondent.session, do: Session.load(respondent.session), else: respondent.session
      RetriesHistogram.next_step(respondent, session, next_action)
    end
    next_action
  end
end
