defmodule Ask.Runtime.Broker do
  use GenServer
  use Timex
  import Ecto.Query
  import Ecto
  alias Ask.{Repo, Survey, Respondent, RespondentDispositionHistory, RespondentGroup, QuotaBucket}
  alias Ask.Runtime.{Session, Reply}
  alias Ask.QuotaBucket
  require Logger

  @poll_interval :timer.minutes(1)
  @server_ref {:global, __MODULE__}

  def server_ref, do: @server_ref

  def start_link do
    GenServer.start_link(__MODULE__, [], name: @server_ref)
  end

  def sync_step(respondent, reply) do
    GenServer.call(@server_ref, {:sync_step, respondent, reply})
  end

  def channel_failed(respondent, token) do
    GenServer.call(@server_ref, {:channel_failed, respondent, token})
  end

  # Makes the borker performs a poll on the surveys.
  # This method is intended to be used by tests.
  def poll do
    GenServer.call(@server_ref, :poll)
  end

  def init(_args) do
    :timer.send_interval(@poll_interval, :poll)
    {:ok, nil}
  end

  def handle_info(:poll, state, now \\ Timex.now) do
    Repo.all(from r in Respondent, where: r.state == "active" and r.timeout_at <= ^now)
    |> Enum.each(&retry_respondent(&1))

    schedule = today_schedule()

    surveys = Repo.all(from s in Survey, where: s.state == "running" and fragment("(? & ?) = ?", s.schedule_day_of_week, ^schedule, ^schedule))

    surveys |> Enum.filter( fn s ->
                  s.schedule_start_time <= Ecto.Time.cast!(Timex.Timezone.convert(now, s.timezone))
                  && s.schedule_end_time >= Ecto.Time.cast!(Timex.Timezone.convert(now, s.timezone))
               end)
            |> Enum.each(&poll_survey(&1))

    {:noreply, state}
  end

  def handle_call({:sync_step, respondent, reply}, _from, state) do
    {:reply, do_sync_step(respondent, reply), state}
  end

  def handle_call(:poll, _from, state) do
    handle_info(:poll, state)
    {:reply, :ok, state}
  end

  def handle_call({:channel_failed, respondent, token}, _from, state) do
    session = respondent.session |> Session.load
    case Session.channel_failed(session, token) do
      :ok -> :ok
      :failed ->
        update_respondent(respondent, :failed)
    end
    {:reply, :ok, state}
  end

  defp poll_survey(survey) do
    try do
      by_state = Repo.all(
        from r in assoc(survey, :respondents),
        group_by: :state,
        select: {r.state, count("*")}) |> Enum.into(%{})

      active = by_state["active"] || 0
      pending = by_state["pending"] || 0
      completed = by_state["completed"] || 0
      stalled = by_state["stalled"] || 0
      reached_quotas = reached_quotas?(survey)

      cond do
        reached_quotas || (active == 0 && ((pending + stalled) == 0 || survey.cutoff <= completed)) ->
          complete(survey)

        active < batch_size() && pending > 0 ->
          start_some(survey, batch_size() - active)

        true -> :ok
      end
    rescue
      e ->
        if Mix.env != :test do
          Logger.error "Error occurred while polling survey (id: #{survey.id}): #{inspect e} #{inspect System.stacktrace}"
        end
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
    |> Repo.update_all(set: [state: "failed"])
  end

  defp start_some(survey, count) do
    (from r in assoc(survey, :respondents),
      where: r.state == "pending",
      limit: ^count)
    |> preload(respondent_group: :channels)
    |> Repo.all
    |> Enum.each(&start(survey, &1))
  end

  defp retry_respondent(respondent) do
    session = respondent.session |> Session.load

    handle_session_step(respondent, Session.timeout(session))
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

    handle_session_step(respondent, Session.start(questionnaire, respondent, primary_channel, retries, fallback_channel, fallback_retries, fallback_delay, survey.count_partial_results))
  end

  defp select_questionnaire_and_mode(survey = %Survey{comparisons: []}) do
    {hd(survey.questionnaires), hd(survey.mode)}
  end

  defp select_questionnaire_and_mode(survey = %Survey{comparisons: comparisons}) do
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

  defp do_sync_step(respondent, reply) do
    session = respondent.session |> Session.load

    try do
      handle_session_step(respondent, Session.sync_step(session, reply))
    rescue
      e ->
        if Mix.env != :test do
          Logger.error "Error occurred while processing sync step (survey_id: #{respondent.survey_id}, respondent_id: #{respondent.id}): #{inspect e} #{inspect System.stacktrace}"
        end
        Sentry.capture_exception(e, [
          stacktrace: System.stacktrace(),
          extra: %{survey_id: respondent.survey_id, respondent_id: respondent.id}])

        Survey
        |> Repo.get(respondent.survey_id)
        |> complete
    end
  end

  defp handle_session_step(respondent, {:ok, session, reply, timeout}) do
    update_respondent(respondent, {:ok, session, timeout}, Reply.disposition(reply))
    {:prompts, Reply.prompts(reply)}
  end

  defp handle_session_step(respondent, {:end, reply}) do
    update_respondent(respondent, :end)
    {:end, {:prompts, Reply.prompts(reply)}}
  end

  defp handle_session_step(respondent, :end) do
    update_respondent(respondent, :end)
    :end
  end

  defp handle_session_step(respondent, {:rejected, reply}) do
    update_respondent(respondent, :rejected)
    {:end, {:prompts, Reply.prompts(reply)}}
  end

  defp handle_session_step(respondent, :rejected) do
    update_respondent(respondent, :rejected)
    :end
  end

  defp handle_session_step(respondent, {:stalled, session}) do
    update_respondent(respondent, {:stalled, session})
  end

  defp handle_session_step(respondent, :failed) do
    update_respondent(respondent, :failed)
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
    old_disposition = respondent.disposition

    # If the current disposition is ineligible we shouldn't mark the respondent
    # as completed (#639).
    # If the respondent has partial disposition, or no disposition at all,
    # then it's OK to mark it as completed.
    new_disposition =
      if old_disposition == "ineligible" do
        old_disposition
      else
        "completed"
      end

    respondent
    |> Respondent.changeset(%{state: "completed", disposition: new_disposition, session: nil, completed_at: Timex.now, timeout_at: nil})
    |> Repo.update!
    |> create_disposition_history(old_disposition)
    |> update_quota_bucket(old_disposition, respondent.session["count_partial_results"])
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

  defp update_respondent(respondent, {:ok, session, timeout}, nil) do
    timeout_at = Timex.shift(Timex.now, minutes: timeout)
    respondent
    |> Respondent.changeset(%{state: "active", session: Session.dump(session), timeout_at: timeout_at})
    |> Repo.update!
  end

  defp update_respondent(respondent, {:ok, session, timeout}, disposition) do
    old_disposition = respondent.disposition
    if shouldnt_update_disposition(old_disposition, disposition) do
      update_respondent(respondent, {:ok, session, timeout}, nil)
    else
      timeout_at = Timex.shift(Timex.now, minutes: timeout)
      respondent
      |> Respondent.changeset(%{disposition: disposition, state: "active", session: Session.dump(session), timeout_at: timeout_at})
      |> Repo.update!
      |> create_disposition_history(old_disposition)
      |> update_quota_bucket(old_disposition, session.count_partial_results)
    end
  end

  defp shouldnt_update_disposition(old_disposition, new_disposition) do
    (old_disposition == "completed"
    || old_disposition == "ineligible"
    || (new_disposition == "ineligible" && old_disposition == "partial"))
  end

  defp create_disposition_history(respondent, old_disposition) do
    if respondent.disposition && respondent.disposition != old_disposition do
      %RespondentDispositionHistory{
        respondent: respondent,
        disposition: respondent.disposition}
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

  defp today_schedule do
    week_day = Timex.weekday(Timex.today)
    schedule = %Ask.DayOfWeek{
      mon: week_day == 1,
      tue: week_day == 2,
      wed: week_day == 3,
      thu: week_day == 4,
      fri: week_day == 5,
      sat: week_day == 6,
      sun: week_day == 7}
    {:ok, schedule} = Ask.DayOfWeek.dump(schedule)
    schedule
  end

  defp batch_size do
    case Application.get_env(:ask, __MODULE__)[:batch_size] do
      {:system, env_var} ->
        String.to_integer(System.get_env(env_var))
      {:system, env_var, default} ->
        env_value = System.get_env(env_var)
        if env_value do
          String.to_integer(env_value)
        else
          default
        end
      value -> value
    end
  end
end
