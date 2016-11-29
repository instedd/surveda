defmodule Ask.Runtime.Broker do
  use GenServer
  use Timex
  import Ecto.Query
  import Ecto
  alias Ask.{Repo, Survey, Respondent}
  alias Ask.Runtime.Session
  alias Ask.QuotaBucket
  alias Ask.Response

  @batch_size 10
  @poll_interval :timer.minutes(1)
  @server_ref {:global, __MODULE__}

  def server_ref, do: @server_ref

  def start_link do
    GenServer.start_link(__MODULE__, [], name: @server_ref)
  end

  def sync_step(respondent, reply) do
    GenServer.call(@server_ref, {:sync_step, respondent, reply})
  end

  def init(_args) do
    :timer.send_interval(@poll_interval, :poll)
    {:ok, nil}
  end

  def handle_info(:poll, state, now \\ Timex.now) do
    Repo.all(from r in Respondent, where: r.state == "active" and r.timeout_at <= ^now)
    |> Enum.each(&retry_respondent(&1))

    ischedule = today_schedule()

    surveys = Repo.all(from s in Survey, where: s.state == "running" and fragment("(? & ?) = ?", s.schedule_day_of_week, ^ischedule, ^ischedule))

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

  defp poll_survey(survey) do
    by_state = Repo.all(
      from r in assoc(survey, :respondents),
      group_by: :state,
      select: {r.state, count("*")}) |> Enum.into(%{})

    active = by_state["active"] || 0
    pending = by_state["pending"] || 0
    completed = by_state["completed"] || 0
    stalled = by_state["stalled"] || 0

    cond do
      active == 0 && ((pending + stalled) == 0 || survey.cutoff <= completed) ->
        complete(survey)

      active < @batch_size && pending > 0 ->
        start_some(survey, @batch_size - active)

      true -> :ok
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
    respondents = Repo.all(
      from r in assoc(survey, :respondents),
      where: r.state == "pending",
      limit: ^count)

    respondents |> Enum.each(&start(survey, &1))
  end

  defp retry_respondent(respondent) do
    session = respondent.session |> Session.load

    case Session.timeout(session) do
      {:stalled, session} ->
        update_respondent(respondent, {:stalled, session})
      :failed ->
        update_respondent(respondent, :failed)
      {session, timeout} ->
        update_respondent(respondent, {:ok, session, timeout})
    end
  end

  defp start(survey, respondent) do
    survey = Repo.preload(survey, [:questionnaire, :channels])
    primary_channel = Survey.primary_channel(survey)
    fallback_channel = Survey.fallback_channel(survey)

    retries = Survey.retries_configuration(survey, primary_channel.type)
    fallback_retries = case fallback_channel do
      nil -> []
      _ -> Survey.retries_configuration(survey, fallback_channel.type)
    end

    case Session.start(survey.questionnaire, respondent, primary_channel, retries, fallback_channel, fallback_retries) do
      :end ->
        update_respondent(respondent, :end)

      {session, timeout} ->
        update_respondent(respondent, {:ok, session, timeout})
    end
  end

  defp do_sync_step(respondent, reply) do
    session = respondent.session |> Session.load

    case Session.sync_step(session, reply) do
      {:ok, session, step, timeout} ->
        update_respondent(respondent, {:ok, session, timeout})
        step

      :end ->
        update_respondent(respondent, :end)
        :end
    end
  end

  defp match_condition(responses, bucket) do
    bucket_vars = Map.keys(bucket.condition)

    matches = Enum.all?( bucket_vars, fn var ->
                Enum.any?(responses, fn res ->
                  (res.field_name == var) && (res.value == Map.fetch!(bucket.condition, var))
                end)
              end)
              
    matches
  end

  defp update_respondent(respondent, :end) do
    respondent
    |> Respondent.changeset(%{state: "completed", session: nil, completed_at: Timex.now, timeout_at: nil})
    |> Repo.update

    responses = Repo.all(from r in Response, where: r.respondent_id == ^respondent.id)
    matching_bucket = Repo.all(from b in QuotaBucket, where: b.survey_id == ^respondent.survey_id)
                    |> Enum.find( fn bucket -> match_condition(responses, bucket) end )

    if matching_bucket do
      Ask.Repo.query!("update quota_buckets set count = count + 1 where id = ?", [matching_bucket.id])
    end
  end

  defp update_respondent(respondent, {:stalled, session}) do
    respondent
    |> Respondent.changeset(%{state: "stalled", session: Session.dump(session), timeout_at: nil})
    |> Repo.update
  end

  defp update_respondent(respondent, :failed) do
    respondent
    |> Respondent.changeset(%{state: "failed", session: nil, timeout_at: nil})
    |> Repo.update
  end

  defp update_respondent(respondent, {:ok, session, timeout}) do
    timeout_at = Timex.shift(Timex.now, minutes: timeout)
    respondent
    |> Respondent.changeset(%{state: "active", session: Session.dump(session), timeout_at: timeout_at})
    |> Repo.update
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
    {:ok, ischedule} = Ask.DayOfWeek.dump(schedule)
    ischedule
  end

end
