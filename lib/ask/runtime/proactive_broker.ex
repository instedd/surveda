defmodule Ask.Runtime.ProactiveBroker do
  use GenServer
  import Ecto.Query
  import Ecto
  alias Ask.{Repo, Logger, Survey, Respondent, RespondentGroup, QuotaBucket, RespondentDispositionHistory, SystemTime, Schedule, SurvedaMetrics}
  alias Ask.Runtime.{Session, Broker, RetriesHistogram, ChannelStatusServer}

  @poll_interval :timer.minutes(1)
  @server_ref {:global, __MODULE__}

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
    Logger.info "Broker started. Default batch size=#{default_batch_size()}. Limit per minute=#{batch_limit_per_minute()}."
    {:ok, nil}
  end

  def handle_info(:poll, state, now) do
    try do
      mark_stalled_for_eight_hours_respondents_as_failed()

      Repo.all(from r in Respondent, where: r.state == "active" and r.timeout_at <= ^now, limit: ^batch_limit_per_minute())
      |> Enum.each(&retry_respondent(&1))

      all_running_surveys()
      |> Enum.filter(&Schedule.intersect?(&1.schedule, now))
      |> Enum.each(&poll_survey/1)

      {:noreply, state}
    after
      :timer.send_after(@poll_interval, :poll)
    end
  end

  def handle_info(:poll, state) do
    handle_info(:poll, state, SystemTime.time.now)
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  def handle_call(:poll, _from, state) do
    handle_info(:poll, state)
    {:reply, :ok, state}
  end

  # visible for testing
  def retry_respondent(respondent) do
    session = respondent.session |> Session.load

    Repo.transaction(fn ->
      try do
        Broker.handle_session_step(Session.timeout(session), SystemTime.time.now)
      rescue
        e in Ecto.StaleEntryError ->
          Logger.error(inspect e)
          # Maybe sync_step or another action was executed while the timeout was executed,
          # and that means the respondent reply, so we don't need to apply the timeout anymore
          Repo.rollback(e)
      end
    end)
  end

  # visible for testing
  def configure_new_respondent(respondent, questionnaire_id, sequence_mode) do
    {primary_mode, _} = get_modes(sequence_mode)
    respondent
    |> Respondent.changeset(%{questionnaire_id: questionnaire_id, mode: sequence_mode, disposition: "queued"})
    |> Repo.update!
    |> RespondentDispositionHistory.create(respondent.disposition, primary_mode)
  end

  defp poll_survey(survey) do
    channels = survey |> Survey.survey_channels
    channel_is_down = channels |> Enum.any?(fn c ->
      status = c.id |> ChannelStatusServer.get_channel_status
      (status != :up && status != :unknown)
    end)
    case channel_is_down do
      false ->
        try do
          by_state = Survey.respondents_by_state(survey)
          %{
            "active" => active,
            "pending" => pending,
            "completed" => completed,
            "stalled" => stalled,
          } = by_state

          reached_quotas = reached_quotas?(survey)
          survey_completed = survey.cutoff <= completed || reached_quotas
          batch_size = batch_size(survey, by_state)
          Logger.info "Polling survey #{survey.id} (active=#{active}, pending=#{pending}, completed=#{completed}, stalled=#{stalled}, batch_size=#{batch_size})"
          SurvedaMetrics.increment_counter_with_label(:surveda_survey_poll, [survey.id])

          cond do
            (active == 0 && ((pending + stalled) == 0 || survey_completed)) ->
              Logger.info "Survey #{survey.id} completed"
              complete(survey)

            (active + stalled) < batch_size && pending > 0 && !survey_completed ->
              count = batch_size - (active + stalled)
              Logger.info "Survey #{survey.id}. Starting up to #{count} respondents."
              start_some(survey, count)

            true -> :ok
          end
        rescue
          e ->
            if Mix.env == :test do
              IO.inspect e
              IO.inspect System.stacktrace()
              raise e
            end
            Logger.error(e, "Error occurred while polling survey (id: #{survey.id})")
            Sentry.capture_exception(e, [
              stacktrace: System.stacktrace(),
              extra: %{survey_id: survey.id}])
        end
      true ->
        ChannelStatusServer.log_info "Survey #{survey.id} was not polled because a channel is down"
    end
  end

  defp all_running_surveys do
    Repo.all(from s in Survey, where: s.state == "running",
                               preload: [respondent_groups: [respondent_group_channels: :channel]]
    )
  end

  defp start(survey, respondent) do
    survey = Repo.preload(survey, [:questionnaires])
    group = respondent.respondent_group

    {questionnaire, mode} = select_questionnaire_and_mode(survey)

    {primary_mode, fallback_mode} = get_modes(mode)

    # Set respondent questionnaire and mode
    respondent = configure_new_respondent(respondent, questionnaire.id, mode)

    primary_channel = RespondentGroup.primary_channel(group, mode)
    fallback_channel = RespondentGroup.fallback_channel(group, mode)

    retries = Survey.retries_configuration(survey, primary_mode)
    fallback_retries = case fallback_channel do
      nil -> []
      _ -> Survey.retries_configuration(survey, fallback_mode)
    end

    fallback_delay = survey |> Survey.fallback_delay()
    SurvedaMetrics.increment_counter_with_label(:surveda_broker_respondent_start, [survey.id])
    Session.start(questionnaire, respondent, primary_channel, primary_mode, survey.schedule, retries, fallback_channel, fallback_mode, fallback_retries, fallback_delay, survey.count_partial_results)
    |> handle_session_started
    |> Broker.handle_session_step(SystemTime.time.now)
  end

  defp default_batch_size do
    Survey.environment_variable_named(:batch_size)
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

  # Estimates the amount of respondents the broker will have to initiate contact with
  # to get the completed respondents needed.
  defp batch_size(survey, respondents_by_state) do
    case Survey.completed_respondents_needed_by(survey) do
      :all ->
        default_batch_size()

      respondents_target when is_integer(respondents_target) ->
        successful = Survey.completed_state_respondents(survey, respondents_by_state)
        estimated_success_rate = estimated_success_rate(survey, respondents_target)
        (respondents_target - successful) / estimated_success_rate
        |> trunc
    end
  end

  defp mark_stalled_for_eight_hours_respondents_as_failed do
    eight_hours_ago = SystemTime.time.now |> Timex.shift(hours: -8)

    (from r in Respondent,
          where: r.state == "stalled",
          where: r.updated_at <= ^eight_hours_ago)
    |> Repo.all
    |> Enum.each(fn respondent ->
      respondent = RetriesHistogram.remove_respondent(respondent)
      Broker.update_respondent(respondent, :failed)
    end)
  end

  defp batch_limit_per_minute do
    Survey.environment_variable_named(:batch_limit_per_minute)
  end

  defp complete(survey) do
    Repo.update Survey.changeset(survey, %{state: "terminated", exit_code: 0, exit_message: "Successfully completed"})
    set_stalled_respondents_as_failed(survey)
  end

  defp set_stalled_respondents_as_failed(survey) do
    from(r in assoc(survey, :respondents), where: r.state == "stalled")
    |> Repo.update_all(set: [state: "failed", session: nil, timeout_at: nil])
  end

  defp start_some(survey, count) do
    count = Enum.min([batch_limit_per_minute(), count])

    (from r in assoc(survey, :respondents),
          where: r.state == "pending",
          limit: ^count)
    |> preload(respondent_group: [respondent_group_channels: :channel])
    |> Repo.all
    |> Enum.each(&start(survey, &1))
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
      total_count = total_count + (ratio || 0)
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

  defp get_modes(sequence_mode) do
    case sequence_mode do
      [primary] -> {primary, nil}
      [primary, fallback] -> {primary, fallback}
    end
  end

  defp handle_session_started(session_started)do
    case session_started do
      {:ok, session, reply, timeout} -> {:ok, %Session{session | respondent: RetriesHistogram.add_new_respondent(session.respondent, session, timeout)}, reply, timeout}
      other -> other
    end
  end

  defp estimated_success_rate(survey, respondents_target) do
    respondents_by_disposition = survey |> Survey.respondents_by_disposition
    completion_rate = Survey.get_completion_rate(survey, respondents_by_disposition, respondents_target)
    current_success_rate = Survey.get_success_rate(survey, respondents_by_disposition )
    initial_success_rate = Survey.initial_success_rate()
    Survey.estimated_success_rate(initial_success_rate, current_success_rate, completion_rate)
  end
end