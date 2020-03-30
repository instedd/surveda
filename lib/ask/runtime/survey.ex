defmodule Ask.Runtime.Survey do
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

  # We expose this method so we can test that if a stale respondent is
  # passed, it's reloaded and the action is retried (this can happen
  # if a timeout happens in between this call)
  def sync_step_internal(session, reply) do
    sync_step_internal(session, reply, session.current_mode, SystemTime.time.now)
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

#  def respondent_by() do
#
#  end
#
#  def save_respondent(respondent, changes) do
#    respondent
#    |> Respondent.changeset(changes)
#    |> Repo.update!
#  end
#
#  def reply(status, reply) do
#
#  end

  def handle_session_step(session_step, now, offline \\ true)

  def handle_session_step({:ok, %{respondent: respondent} = session, reply, timeout}, now, offline) do
#    update_respondent(respondent, {:ok, session, timeout}, Reply.disposition(reply), now)
    timeout_at = Respondent.next_actual_timeout(respondent, timeout, now)
    respondent_updates(:ok, respondent, session, Reply.disposition(reply), timeout_at, offline)
    {:reply, reply}
  end

  def handle_session_step({:hangup, session, reply, timeout, respondent}, _, offline) do
#    update_respondent(respondent, {:ok, session, timeout}, Reply.disposition(reply), SystemTime.time.now)
    timeout_at = Respondent.next_actual_timeout(respondent, timeout, SystemTime.time.now)
    respondent_updates(:ok, respondent, session, Reply.disposition(reply), timeout_at, offline)
    :end
  end

  def handle_session_step({:end, reply, respondent}, _, offline) do
#    update_respondent(respondent, :end, Reply.disposition(reply), nil)

    {session, mode} = case respondent.session do
      nil -> {nil, nil}
      session ->
        session = session |> Session.load
        mode = session.current_mode |> SessionMode.mode
        {session, mode}
    end

    old_disposition = respondent.disposition
    reply_disposition = Reply.disposition(reply)

    new_disposition = old_disposition
                      |> Flow.resulting_disposition(reply_disposition)
                      |> Flow.resulting_disposition("completed")
    # If new_disposition == reply_disposition, change of disposition has already been logged during Session.sync_step
    # TODO: why only here and not in update_respondent_and_set_disposition?

    #TODO: use update_respondent_and_set_disposition
    if session && new_disposition != old_disposition && new_disposition != reply_disposition do
      Session.log_disposition_changed(respondent, session.current_mode.channel, mode, old_disposition, new_disposition)
    end

    respondent_updates(:end, respondent, new_disposition, offline)

    case Reply.steps(reply) do
      [] ->
        :end
      _ ->
        {:end, {:reply, reply}}
    end
  end

  def handle_session_step({:rejected, reply, respondent}, _, offline) do
#    update_respondent(respondent, :rejected)
    respondent_updates(:rejected, respondent, nil, nil, offline)
    {:end, {:reply, reply}}
  end

  def handle_session_step({:rejected, %{respondent: respondent} = session, reply, timeout}, _, offline) do
#    update_respondent(respondent, {:rejected, session, timeout})
    timeout_at = Respondent.next_actual_timeout(respondent, timeout, SystemTime.time.now)
    respondent_updates(:rejected, respondent, session, timeout_at, offline)
    {:reply, reply}
  end

  def handle_session_step({:rejected, respondent}, _, offline) do
#    update_respondent(respondent, :rejected)
    respondent_updates(:rejected, respondent, nil, nil, offline)
    :end
  end

  def handle_session_step({:stopped, reply, respondent}, _, offline) do
#    update_respondent(respondent, :stopped, Reply.disposition(reply), nil)
    respondent_updates(:stopped, respondent, Reply.disposition(reply), offline) # TODO: update_respondent_and_set_disposition
    :end
  end

  def handle_session_step({:failed, respondent}, _, offline) do
#    update_respondent(respondent, :failed)
    respondent_updates(:failed, respondent, offline) #TODO: update_respondent_and_set_disposition
    :end
  end

#   TODO: was not being used?
#  def update_respondent(%Respondent{} = respondent, :end) do
#    update_respondent(respondent, :end, nil, nil)
#  end

#  def update_respondent(%Respondent{} = respondent, {:stalled, session}) do #1
#    respondent
#    |> Respondent.changeset(%{state: "stalled", session: Session.dump(session), timeout_at: nil})
#    |> Repo.update!

    # ========
#    changes = respondent_updates(:stalled, respondent, session)
#    do_update_respondent(respondent, changes)
#  end

#  def update_respondent(%Respondent{} = respondent, :rejected) do #2
#    respondent
#    |> Respondent.changeset(%{state: "rejected", session: nil, timeout_at: nil})
#    |> Repo.update!

    # =======
#    changes = respondent_updates(:rejected, respondent, nil, nil)
#    do_update_respondent(respondent, changes)
#  end

#  def update_respondent(%Respondent{} = respondent, {:rejected, session, timeout}) do #2
#    respondent
#      |> Respondent.changeset(%{state: "rejected", session: Session.dump(session), timeout_at: timeout_at})
#      |> Repo.update!

    # ====
#    timeout_at = Respondent.next_actual_timeout(respondent, timeout, SystemTime.time.now)
#    changes = respondent_updates(:rejected, respondent, session, timeout_at)
#    do_update_respondent(respondent, changes)
#  end

#  def update_respondent(%Respondent{} = respondent, :failed) do #5
#
#    respondent
#    |> Respondent.changeset(%{state: "failed", session: nil, timeout_at: nil, disposition: new_disposition})
#    |> Repo.update!
#    |> RespondentDispositionHistory.create(old_disposition, mode)

    # ============

#    session = respondent.session |> Session.load
#    mode = session.current_mode |> SessionMode.mode
#    old_disposition = respondent.disposition
#    new_disposition = Flow.failed_disposition_from(respondent.disposition)

#    Session.log_disposition_changed(respondent, session.current_mode.channel, mode, old_disposition, new_disposition)

#    changes = respondent_updates(:failed, respondent)
#    do_update_respondent(respondent, changes) #TODO: update_respondent_and_set_disposition
#  end

#  def update_respondent(%Respondent{} = respondent, :stopped, disposition, _) do #4
#    session = respondent.session |> Session.load
#    update_respondent_and_set_disposition(respondent, session, nil, %{disposition: disposition, state: "failed", session: nil, timeout_at: nil, user_stopped: true})

   # =========
#    changes = respondent_updates(:stopped, disposition)
#    do_update_respondent(respondent, changes)
#  end

#  def update_respondent(%Respondent{} = respondent, {:ok, session, timeout}, nil, now) do #7 TODO: use respondent_updates
#    effective_modes = respondent.effective_modes || []
#    effective_modes =
#      if session do
#        mode = Ask.Runtime.SessionMode.mode(session.current_mode)
#        Enum.uniq(effective_modes ++ [mode])
#      else
#        effective_modes
#      end

#    timeout_at = Respondent.next_actual_timeout(respondent, timeout, now)
#    respondent
#    |> Respondent.changeset(%{state: "active", session: Session.dump(session), timeout_at: timeout_at, language: session.flow.language, effective_modes: effective_modes})
#    |> Repo.update!
#  end

#  def update_respondent(%Respondent{} = respondent, {:ok, session, timeout}, disposition, _) do #6
#    timeout_at = Respondent.next_actual_timeout(respondent, timeout, SystemTime.time.now)
#    update_respondent_and_set_disposition(respondent, session, timeout, %{session: Session.dump(session), timeout_at: timeout_at, disposition: disposition, state: "active"})
#    changes = respondent_updates(:ok, respondent session, disposition, timeout_at)
#    do_update_respondent() #TODO: update_respondent_and_set_disposition
#  end

#  def update_respondent(%Respondent{} = respondent, :end, reply_disposition, _) do #3
#    [session, mode] = case respondent.session do
#      nil -> [nil, nil]
#      session ->
#        session = session |> Session.load
#        mode = session.current_mode |> SessionMode.mode
#        [session, mode]
#    end
#
#    old_disposition = respondent.disposition
#
#    new_disposition =
#      old_disposition
#      |> Flow.resulting_disposition(reply_disposition)
#      |> Flow.resulting_disposition("completed")

    #    respondent
    #    |> Respondent.changeset(%{state: "completed", disposition: new_disposition, session: nil, completed_at: SystemTime.time.now, timeout_at: nil})
    #    |> Repo.update!
    #    |> RespondentDispositionHistory.create(old_disposition, mode) #TODO: update_respondent_and_set_disposition?
    #    |> update_quota_bucket(old_disposition, respondent.session["count_partial_results"])

    # ==============

#    # If new_disposition == reply_disposition, change of disposition has already been logged during Session.sync_step
#    # TODO: why only here and not in update_respondent_and_set_disposition?
#    if session && new_disposition != old_disposition && new_disposition != reply_disposition do
#      Session.log_disposition_changed(respondent, session.current_mode.channel, mode, old_disposition, new_disposition)
#    end
#
#    changes = respondent_updates(:end, respondent)
#    do_update_respondent(respondent, changes)
#  end

  # ========================
  #   Respondent updates
  # ========================
  def do_update_respondent(respondent, changes, offline) do
    #TODO: check if disposition changed -> update_respondent_and_set_disposition

    if(offline) do
      respondent
      |> Respondent.changeset(changes)
      |> Repo.update!
    else
      Map.merge(respondent, changes)
    end
  end

  def respondent_updates(:failed, respondent, offline) do #5
    new_disposition = Flow.failed_disposition_from(respondent.disposition)
    changes = %{state: "failed", session: nil, timeout_at: nil, disposition: new_disposition}
    do_update_respondent(respondent, changes, offline)
  end

  def respondent_updates(:stalled, respondent, session, offline) do #1
    changes = %{state: "stalled", session: Session.dump(session), timeout_at: nil}
    do_update_respondent(respondent, changes, offline)
  end

  def respondent_updates(:end, respondent, disposition, offline) do #3
    changes = %{state: "completed", disposition: disposition, session: nil, completed_at: SystemTime.time.now, timeout_at: nil}
    do_update_respondent(respondent, changes, offline)
  end

  def respondent_updates(:stopped, respondent, disposition, offline) do #4
    changes = %{disposition: disposition, state: "failed", session: nil, timeout_at: nil, user_stopped: true}
    do_update_respondent(respondent, changes, offline)
  end

  def respondent_updates(:rejected, respondent, session, timeout_at, offline) do #2
    session = if session != nil, do: Session.dump(session), else: nil
    changes = %{state: "rejected", session: session, timeout_at: timeout_at}
    do_update_respondent(respondent, changes, offline)
  end

  def respondent_updates(:no_disposition, respondent, session, timeout_at, offline) do #7 end
    effective_modes = respondent.effective_modes || []
    effective_modes =
      if session do
        mode = Ask.Runtime.SessionMode.mode(session.current_mode)
        Enum.uniq(effective_modes ++ [mode])
      else
        effective_modes
      end

    changes = %{state: "active", session: Session.dump(session), timeout_at: timeout_at, language: session.flow.language, effective_modes: effective_modes}
    do_update_respondent(respondent, changes, offline)
  end

  def respondent_updates(:ok, respondent, session, disposition, timeout_at, offline) do #6 set_disposition
    if disposition do
      changes = %{session: Session.dump(session), timeout_at: timeout_at, disposition: disposition, state: "active"}
      do_update_respondent(respondent, changes, offline) #TODO: update_respondent_and_set_disposition
    else
      respondent_updates(:no_disposition, respondent, session, timeout_at, offline)
    end
  end

  def channel_failed(respondent, reason \\ "failed", offline \\ true) do
    session = respondent.session
    if session do
      session = session |> Session.load
      case Session.channel_failed(session, reason) do
        :ok -> :ok
        :failed ->
          # respondent no longer participates in the survey (no attempts left)
          respondent = RetriesHistogram.remove_respondent(respondent)
          respondent_updates(:failed, respondent, offline)
      end
    else
      :ok
    end
  end

  def contact_attempt_expired(respondent, offline \\ true) do
    session = respondent.session
    if session do
      response = session
                 |> Session.load
                 |> Session.contact_attempt_expired

#      update_respondent(respondent, response, nil, SystemTime.time.now)
      {:ok, _session, timeout} = response
      timeout_at = Respondent.next_actual_timeout(respondent, timeout, SystemTime.time.now)
      respondent_updates(:no_disposition, respondent, session, timeout_at, offline)
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

  defp sync_step_internal(_, _, :invalid_mode, _) do
    :end
  end

  defp sync_step_internal(session, reply, session_mode, now) do
    transaction_result = Repo.transaction(fn ->
      try do
        reply = mask_phone_number(session.respondent, reply)
        session_step = Session.sync_step(session, reply, session_mode)
        handle_session_step(session_step, now)
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

  defp update_respondent_and_set_disposition(respondent, session, timeout, %{disposition: disposition} =  changes, offline) do
    old_disposition = respondent.disposition
    if Flow.should_update_disposition(old_disposition, disposition) do
      #TODO:
      #     Session.log_disposition_changed(respondent, session.current_mode.channel, mode, old_disposition, new_disposition)
      respondent
      |> Respondent.changeset(changes)
      |> Repo.update!
      |> RespondentDispositionHistory.create(old_disposition, session.current_mode |> SessionMode.mode)
      |> update_quota_bucket(old_disposition, session.count_partial_results)
    else
#      update_respondent(respondent, {:ok, session, timeout}, nil, SystemTime.time.now)
      respondent_updates(:no_disposition, respondent, session, timeout, offline)
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

  defp handle_next_action(next_action, respondent_id) do
    respondent = Repo.get(Respondent, respondent_id)
    session = if respondent.session, do: Session.load(respondent.session), else: respondent.session
    RetriesHistogram.next_step(respondent, session, next_action)
    next_action
  end
end
