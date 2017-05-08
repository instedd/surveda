defmodule Ask.Runtime.Broker do
  use GenServer
  use Timex
  import Ecto.Query
  import Ecto
  alias Ask.{Repo, Survey, Respondent, RespondentDispositionHistory, RespondentGroup, QuotaBucket, Logger}
  alias Ask.Runtime.{Session, Reply, Flow, SessionMode}
  alias Ask.QuotaBucket

  @poll_interval :timer.minutes(1)
  @server_ref {:global, __MODULE__}
  @batch_limit 100

  def server_ref, do: @server_ref

  def start_link do
    GenServer.start_link(__MODULE__, [], name: @server_ref)
  end

  # Makes the borker performs a poll on the surveys.
  # This method is intended to be used by tests.
  def poll do
    GenServer.call(@server_ref, :poll)
  end

  def init(_args) do
    :timer.send_after(1000, :poll)
    {:ok, nil}
  end

  def handle_info(:poll, state, now \\ Timex.now) do
    try do
      mark_stalled_for_eight_hours_respondents_as_failed()

      Repo.all(from r in Respondent, where: r.state == "active" and r.timeout_at <= ^now, limit: @batch_limit)
      |> Enum.each(&retry_respondent(&1))

      all_running_surveys
      |> Enum.filter(&survey_matches_schedule?(&1, now))
      |> Enum.each(&poll_survey/1)

      {:noreply, state}
    after
      :timer.send_after(@poll_interval, :poll)
    end
  end

  def handle_call(:poll, _from, state) do
    handle_info(:poll, state)
    {:reply, :ok, state}
  end

  defp all_running_surveys do
    Repo.all(from s in Survey, where: s.state == "running")
  end

  defp survey_matches_schedule?(survey, now) do
    now_timex = Timex.Timezone.convert(now, survey.timezone)
    now_ecto = Ecto.Time.cast!(now_timex)
    now_schedule = time_to_schedule(now_timex)

    Ask.DayOfWeek.intersect?(now_schedule, survey.schedule_day_of_week) &&
      survey.schedule_start_time <= now_ecto &&
      survey.schedule_end_time >= now_ecto
  end

  defp mark_stalled_for_eight_hours_respondents_as_failed do
    eight_hours_ago = Timex.now |> Timex.shift(hours: -8)

    (from r in Respondent,
      where: r.state == "stalled",
      where: r.updated_at <= ^eight_hours_ago)
    |> Repo.all
    |> Enum.each(fn respondent ->
      update_respondent(respondent, :failed)
    end)
  end

  def channel_failed(respondent, reason \\ "failed") do
    session = respondent.session |> Session.load
    case Session.channel_failed(session, reason) do
      :ok -> :ok
      :failed ->
        update_respondent(respondent, :failed)
    end
  end

  def delivery_confirm(respondent, title) do
    delivery_confirm(respondent, title, nil)
  end

  def delivery_confirm(respondent, title, mode) do
    unless respondent.session == nil do
      session = respondent.session |> Session.load
      session_mode = session_mode(respondent, session, mode)
      Session.delivery_confirm(session, title, session_mode)
    end
  end

  defp respondents_by_state(survey) do
    by_state_defaults = %{
      "active" => 0,
      "pending" => 0,
      "completed" => 0,
      "stalled" => 0,
      "rejected" => 0,
      "failed" => 0,
    }
    Repo.all(
      from r in assoc(survey, :respondents),
      group_by: :state,
      select: {r.state, count("*")})
      |> Enum.into(%{})
      |> (&Map.merge(by_state_defaults, &1)).()
  end

  defp poll_survey(survey) do
    try do
      by_state = respondents_by_state(survey)
      %{
        "active" => active,
        "pending" => pending,
        "completed" => completed,
        "stalled" => stalled,
      } = by_state

      reached_quotas = reached_quotas?(survey)
      survey_completed = survey.cutoff <= completed || reached_quotas
      batch_size = batch_size(survey, by_state)

      cond do
        (active == 0 && ((pending + stalled) == 0 || survey_completed)) ->
          complete(survey)

        (active + stalled) < batch_size && pending > 0 && !survey_completed ->
          start_some(survey, batch_size - (active + stalled))

        true -> :ok
      end
    rescue
      e ->
        Logger.error "Error occurred while polling survey (id: #{survey.id}): #{inspect e} #{inspect System.stacktrace}"
        Sentry.capture_exception(e, [
          stacktrace: System.stacktrace(),
          extra: %{survey_id: survey.id}])
    end
  end

  defp reached_quotas?(survey) do
    case survey.quota_vars do
      [] -> false
      _ ->
        survey_id = survey.id
        Repo.one(from q in QuotaBucket,
          where: q.survey_id == ^survey_id,
          where: q.count < q.quota,
          select: count(q.id)) == 0
    end
  end

  defp complete(survey) do
    Repo.update Survey.changeset(survey, %{state: "completed"})
    set_stalled_respondents_as_failed(survey)
  end

  defp set_stalled_respondents_as_failed(survey) do
    from(r in assoc(survey, :respondents), where: r.state == "stalled")
    |> Repo.update_all(set: [state: "failed", session: nil, timeout_at: nil])
  end

  defp start_some(survey, count) do
    count = Enum.min([@batch_limit, count])

    (from r in assoc(survey, :respondents),
      where: r.state == "pending",
      limit: ^count)
    |> preload(respondent_group: [respondent_group_channels: :channel])
    |> Repo.all
    |> Enum.each(&start(survey, &1))
  end

  def retry_respondent(respondent) do
    session = respondent.session |> Session.load

    Repo.transaction(fn ->
      try do
        handle_session_step(Session.timeout(session))
      rescue
        e in Ecto.StaleEntryError ->
          # Maybe sync_step or another action was executed while the timeout was executed,
          # and that means the respondent reply, so we don't need to apply the timeout anymore
          Repo.rollback(e)
      end
    end)
  end

  defp start(survey, respondent) do
    survey = Repo.preload(survey, [:questionnaires])
    group = respondent.respondent_group

    {questionnaire, mode} = select_questionnaire_and_mode(survey)

    # Set respondent questionnaire and mode
    respondent = respondent
    |> Respondent.changeset(%{questionnaire_id: questionnaire.id, mode: mode})
    |> Repo.update!

    primary_channel = RespondentGroup.primary_channel(group, mode)
    fallback_channel = RespondentGroup.fallback_channel(group, mode)

    retries = Survey.retries_configuration(survey, primary_channel.type)
    fallback_retries = case fallback_channel do
      nil -> []
      _ -> Survey.retries_configuration(survey, fallback_channel.type)
    end

    fallback_delay = Survey.fallback_delay(survey) || Session.default_fallback_delay

    {primary_mode, fallback_mode} = case mode do
      [primary] -> {primary, nil}
      [primary, fallback] -> {primary, fallback}
    end

    handle_session_step(Session.start(questionnaire, respondent, primary_channel, primary_mode, retries, fallback_channel, fallback_mode, fallback_retries, fallback_delay, survey.count_partial_results))
  end

  defp select_questionnaire_and_mode(%Survey{comparisons: []} = survey) do
    {hd(survey.questionnaires), hd(survey.mode)}
  end

  defp select_questionnaire_and_mode(%Survey{comparisons: comparisons} = survey) do
    # Get a random value between 0 and 100
    rand = :rand.uniform() * 100

    # Traverse comparisons:
    #
    # - keep the total ratio so far across visited comparisons
    # - included comparisons are those whose total ratio so far is greater than the rand value
    # - in the end we keep the first comparison that is included
    #
    # For example, if the ratios are [10, 25, 35, 30] and we
    # get a random value of 45, the result of the map_reduce will
    # be [{10, false}, {25, false}, {35, true}, {30, true}] because
    # after the entry with ratio 25 the total accumulated ratio will be
    # 10 + 25 + 35 = 70 >= 45. Then we keep the first one that's true.
    {candidates, _} = comparisons
    |> Enum.map_reduce(0, fn (comparison, total_count) ->
      ratio = comparison["ratio"]
      total_count = total_count + ratio
      included = total_count >= rand
      {{comparison, included}, total_count}
    end)

    candidate = candidates
    |> Enum.find(fn {_, included} -> included end)

    if candidate do
      {comparison, _} = candidate
      questionnaire = survey.questionnaires
      |> Enum.find(fn q -> q.id == comparison["questionnaire_id"] end)
      mode = comparison["mode"]
      {questionnaire, mode}
    else
      # Fall back to first questionnaire and mode, in case
      # the comparisons ratios don't add up 100
      {hd(survey.questionnaires), hd(survey.mode)}
    end
  end

  def sync_step(respondent, reply) do
    session = respondent.session |> Session.load
    sync_step_internal(session, reply, session.current_mode)
  end

  def sync_step(respondent, reply, mode) do
    session = respondent.session |> Session.load
    session_mode = session_mode(respondent, session, mode)
    sync_step_internal(session, reply, session_mode)
  end

  defp session_mode(_respondent, session, :nil) do
    session.current_mode
  end

  defp session_mode(respondent, session, mode) do
    if mode == Ask.Runtime.SessionMode.mode(session.current_mode) do
      session.current_mode
    else
      # We need to find which channel has this mode
      group = (respondent |> Repo.preload(:respondent_group)).respondent_group
      channel = (group |> Repo.preload(:channels)).channels
      |> Enum.find(fn c -> c.type == mode end)

      Ask.Runtime.SessionModeProvider.new(mode, channel, [])
    end
  end

  # We expose this method so we can test that if a stale respondent is
  # passed, it's reloaded and the action is retried (this can happen
  # if a timeout happens in between this call)
  def sync_step_internal(session, reply) do
    sync_step_internal(session, reply, session.current_mode)
  end

  defp sync_step_internal(session, reply, session_mode) do
    respondent = session.respondent

    transaction_result = Repo.transaction(fn ->
      try do
        handle_session_step(Session.sync_step(session, reply, session_mode))
      rescue
        e in Ecto.StaleEntryError ->
          Repo.rollback(e)
        e ->
          Logger.error "Error occurred while processing sync step (survey_id: #{respondent.survey_id}, respondent_id: #{respondent.id}): #{inspect e} #{inspect System.stacktrace}"
          Sentry.capture_exception(e, [
            stacktrace: System.stacktrace(),
            extra: %{survey_id: respondent.survey_id, respondent_id: respondent.id}])

          try do
            handle_session_step({:failed, respondent})
          rescue
            _ ->
              :end
          end
      end
    end)

    case transaction_result do
      {:ok, response} ->
        response
      {:error, %Ecto.StaleEntryError{}} ->
        # Maybe timeout or another action was executed while sync_step was executed, so we need to retry
        sync_step(respondent, reply)
      value ->
        value
    end
  end

  defp handle_session_step({:ok, session, reply, timeout, respondent}) do
    update_respondent(respondent, {:ok, session, timeout}, Reply.disposition(reply))
    {:reply, reply}
  end

  defp handle_session_step({:end, reply, respondent}) do
    update_respondent(respondent, :end, Reply.disposition(reply))

    case Reply.steps(reply) do
      [] ->
        :end
      _ ->
        {:end, {:reply, reply}}
    end
  end

  defp handle_session_step({:rejected, reply, respondent}) do
    update_respondent(respondent, :rejected)
    {:end, {:reply, reply}}
  end

  defp handle_session_step({:rejected, respondent}) do
    update_respondent(respondent, :rejected)
    :end
  end

  defp handle_session_step({:stalled, session, respondent}) do
    update_respondent(respondent, {:stalled, session})
  end

  defp handle_session_step({:stopped, reply, respondent}) do
    update_respondent(respondent, :stopped, Reply.disposition(reply))
    :end
  end

  defp handle_session_step({:failed, respondent}) do
    update_respondent(respondent, :failed)
    :end
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

  defp update_respondent(respondent, :end) do
    update_respondent(respondent, :end, nil)
  end

  defp update_respondent(respondent, {:stalled, session}) do
    respondent
    |> Respondent.changeset(%{state: "stalled", session: Session.dump(session), timeout_at: nil})
    |> Repo.update!
  end

  defp update_respondent(respondent, :rejected) do
    respondent
    |> Respondent.changeset(%{state: "rejected", session: nil, timeout_at: nil})
    |> Repo.update!
  end

  defp update_respondent(respondent, :failed) do
    respondent
    |> Respondent.changeset(%{state: "failed", session: nil, timeout_at: nil})
    |> Repo.update!
  end

  defp update_respondent(respondent, :stopped, disposition) do
    session = respondent.session |> Session.load
    update_respondent_and_set_disposition(respondent, session, nil, nil, nil, disposition, "failed")
  end

  defp update_respondent(respondent, {:ok, session, timeout}, nil) do
    timeout_at = next_timeout(respondent, timeout)
    respondent
    |> Respondent.changeset(%{state: "active", session: Session.dump(session), timeout_at: timeout_at, language: session.flow.language})
    |> Repo.update!
  end

  defp update_respondent(respondent, {:ok, session, timeout}, disposition) do
    update_respondent_and_set_disposition(respondent, session, Session.dump(session), timeout, next_timeout(respondent, timeout), disposition, "active")
  end

  defp update_respondent(respondent, :end, reply_disposition) do
    old_disposition = respondent.disposition

    # If the current disposition is ineligible we shouldn't mark the respondent
    # as completed (#639).
    # If the respondent has partial disposition, or no disposition at all,
    # then it's OK to mark it as completed.
    #
    # Here we also consider the case where a flag step is used at the end of a
    # survey: if the flag step must set the respondent as "ineligible" or
    # "completed" we must do so, unless the respondent is already marked
    # as "completed".
    new_disposition =
      case {old_disposition, reply_disposition} do
        # If the respondent is already completed, ineligible or refused, don't change it
        {"completed", _} -> "completed"
        {"ineligible", _} -> "ineligible"
        {"refused", _} -> "refused"
        # If a flag step sets the respondent as ineligible or refused, do so (the respondent
        # will be an non-set or partial disposition here)
        {_, "ineligible"} -> "ineligible"
        {_, "refused"} -> "refused"
        # In any other case the survey ends and the respondent is marked as completed
        _ -> "completed"
      end

    mode =
      if respondent.session do
        session = respondent.session |> Session.load
        session.current_mode |> SessionMode.mode
      else
        nil
      end

    respondent
    |> Respondent.changeset(%{state: "completed", disposition: new_disposition, session: nil, completed_at: Timex.now, timeout_at: nil})
    |> Repo.update!
    |> create_disposition_history(old_disposition, mode)
    |> update_quota_bucket(old_disposition, respondent.session["count_partial_results"])
  end

  defp update_respondent_and_set_disposition(respondent, session, dump, timeout, timeout_at, disposition, state) do
    old_disposition = respondent.disposition
    if Flow.should_update_disposition(old_disposition, disposition) do
      respondent
      |> Respondent.changeset(%{disposition: disposition, state: state, session: dump, timeout_at: timeout_at})
      |> Repo.update!
      |> create_disposition_history(old_disposition, session.current_mode |> SessionMode.mode)
      |> update_quota_bucket(old_disposition, session.count_partial_results)
    else
      update_respondent(respondent, {:ok, session, timeout}, nil)
    end
  end

  defp next_timeout(respondent, timeout) do
    timeout_at = Timex.shift(Timex.now, minutes: timeout)
    survey = (respondent |> Repo.preload(:survey)).survey
    date_time = survey
    |> Survey.next_available_date_time(timeout_at)
    |> Ecto.DateTime.to_erl
    Timex.Timezone.resolve("UTC", date_time)
  end

  defp create_disposition_history(respondent, old_disposition, mode) do
    if respondent.disposition && respondent.disposition != old_disposition do
      %RespondentDispositionHistory{
        respondent: respondent,
        disposition: respondent.disposition,
        mode: mode}
      |> Repo.insert!
    end
    respondent
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

  defp should_update_quota_bucket(new_disposition, old_disposition, false) do
    new_disposition != old_disposition && new_disposition == "completed"
  end

  defp should_update_quota_bucket(new_disposition, old_disposition, true) do
    (new_disposition != old_disposition && new_disposition == "partial")
    || (new_disposition == "completed" && old_disposition != "partial" && old_disposition != "completed")
  end

  defp time_to_schedule(now) do
    week_day = Timex.weekday(now)
    %Ask.DayOfWeek{
      mon: week_day == 1,
      tue: week_day == 2,
      wed: week_day == 3,
      thu: week_day == 4,
      fri: week_day == 5,
      sat: week_day == 6,
      sun: week_day == 7,
    }
  end

  # Estimates the amount of respondents the broker will have to initiate contact with
  # to get the completed respondents needed.
  defp batch_size(survey, respondents_by_state) do
    case completed_respondents_needed_by(survey) do
      :all -> 
        Survey.environment_variable_named(:batch_size)

      completed_respondents_needed when is_integer(completed_respondents_needed) ->
        current_success_rate = calculate_success_rate(respondents_by_state["completed"], respondents_by_state["failed"], respondents_by_state["rejected"])
        completion_rate = current_completion_rate(respondents_by_state["completed"], completed_respondents_needed)
        estimated_success_rate = estimate_success_rate(completion_rate, current_success_rate)

        batch_size = (completed_respondents_needed-respondents_by_state["completed"])/estimated_success_rate

        batch_size |> trunc
    end
  end

  defp estimate_success_rate(0, _), do: initial_estimated_success_rate()
  defp estimate_success_rate(completion_rate, current_success_rate) do
    %{:response_rate => initial_success_rate } = Survey.config_rates()
    (1-completion_rate) * initial_success_rate + completion_rate * current_success_rate
  end

  defp initial_estimated_success_rate() do
    %{:valid_respondent_rate => initial_valid_respondent_rate,
      :eligibility_rate => initial_eligibility_rate,
      :response_rate => initial_response_rate } = Survey.config_rates()
    initial_valid_respondent_rate * initial_eligibility_rate * initial_response_rate
  end

  defp calculate_success_rate(0, _, _), do: 0
  defp calculate_success_rate(completed_respondents, failed_respondents, rejected_respondents) do
    completed_respondents/(completed_respondents + failed_respondents + rejected_respondents)
  end

  defp current_completion_rate(_, completed_respondents_needed) when is_nil(completed_respondents_needed), do: 0
  defp current_completion_rate(completed, completed_respondents_needed), do: completed/completed_respondents_needed

  defp completed_respondents_needed_by(survey) do
    survey_id = survey.id
    quota_target = Repo.one(from q in QuotaBucket,
                      where: q.survey_id == ^survey_id,
                      select: sum(q.quota))
    cutoff_target = survey.cutoff
    targets_compacted = [quota_target, cutoff_target] |> Enum.reject(&is_nil/1)

    if targets_compacted |> Enum.empty? do
      :all
    else
      res = targets_compacted
            |> Enum.max()
            |> Decimal.new()
            |> Decimal.to_integer()
      res
    end
  end

end
