defmodule Ask.BrokerTest do
  use Ask.ModelCase
  use Ask.DummySteps
  use Timex
  alias Ask.Runtime.Broker
  alias Ask.{Repo, Survey, Respondent, TestChannel}

  @everyday_schedule %Ask.DayOfWeek{mon: true, tue: true, wed: true, thu: true, fri: true, sat: true, sun: true}
  @always_schedule %{schedule_day_of_week: @everyday_schedule,
                     schedule_start_time: elem(Ecto.Time.cast("00:00:00"), 1),
                     schedule_end_time: elem(Ecto.Time.cast("23:59:59"), 1)}

  test "does nothing with 'not_ready' survey" do
    survey = insert(:survey, @always_schedule)
    Broker.handle_info(:poll, nil)

    survey = Repo.get(Survey, survey.id)
    assert survey.state == "not_ready"
  end

  test "set as 'completed' when there is no respondents" do
    survey = insert(:survey, Map.merge(@always_schedule, %{state: "running", timezone: "Etc/UTC"}))
    Broker.handle_info(:poll, nil)

    survey = Repo.get(Survey, survey.id)
    assert survey.state == "completed"
  end

  test "does nothing when there are no pending respondents" do
    survey = insert(:survey, Map.merge(@always_schedule, %{state: "running"}))
    insert(:respondent, survey: survey, state: "active")

    Broker.handle_info(:poll, nil)

    survey = Repo.get(Survey, survey.id)
    assert survey.state == "running"
  end

  test "set the respondent as complete when the questionnaire is empty" do
    [_, _, respondent, _] = create_running_survey_with_channel_and_respondent([])

    Broker.handle_info(:poll, nil)

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "completed"
  end

  test "changes the respondent state from pending to running if neccessary" do
    [survey, _, respondent, _] = create_running_survey_with_channel_and_respondent()

    Broker.handle_info(:poll, nil)

    survey = Repo.get(Survey, survey.id)
    assert survey.state == "running"
    updated_respondent = Repo.get(Respondent, respondent.id)
    assert updated_respondent.state == "active"
  end

  test "marks the survey as completed when the cutoff is reached" do
    [survey, _, _, _] = create_running_survey_with_channel_and_respondent()
    create_several_respondents(survey, 20)

    Repo.update(survey |> change |> Survey.changeset(%{cutoff: 12}))

    Broker.handle_info(:poll, nil)

    survey = Repo.get(Survey, survey.id)

    assert survey.state == "running"

    assert_respondents_by_state(survey, 10, 11)

    Repo.all(from r in Respondent, where: r.state == "active", limit: 5)
    |> Enum.map(fn respondent ->
      Repo.update(respondent |> change |> Respondent.changeset(%{state: "completed"}))
    end)

    Broker.handle_info(:poll, nil)

    assert_respondents_by_state(survey, 7, 9)

    Repo.all(from r in Respondent, where: r.state == "active")
    |> Enum.map(fn respondent ->
      Repo.update(respondent |> change |> Respondent.changeset(%{state: "completed"}))
    end)

    Broker.handle_info(:poll, nil)

    assert_respondents_by_state(survey, 0, 9)

    survey = Repo.get(Survey, survey.id)

    assert survey.state == "completed"
  end

  test "always keeps batch_size number of respondents running" do
    [survey, _, _, _] = create_running_survey_with_channel_and_respondent()
    create_several_respondents(survey, 20)

    Broker.handle_info(:poll, nil)

    survey = Repo.get(Survey, survey.id)

    assert survey.state == "running"

    assert_respondents_by_state(survey, 10, 11)

    active_respondent = Repo.all(from r in Respondent, where: r.state == "active")
    |> Enum.at(0)

    Repo.update(active_respondent |> change |> Respondent.changeset(%{state: "failed"}))

    assert_respondents_by_state(survey, 9, 11)

    Broker.handle_info(:poll, nil)

    assert_respondents_by_state(survey, 10, 10)
  end

  test "changes running survey state to 'completed' when there are no more running respondents" do
    [survey, _, respondent, _] = create_running_survey_with_channel_and_respondent()

    Broker.handle_info(:poll, nil)

    assert_respondents_by_state(survey, 1, 0)

    Repo.update(respondent |> change |> Respondent.changeset(%{state: "failed"}))

    Broker.handle_info(:poll, nil)

    survey = Repo.get(Survey, survey.id)

    assert survey.state == "completed"
  end

  test "respondent flow" do
    [survey, test_channel, respondent, phone_number] = create_running_survey_with_channel_and_respondent()

    {:ok, broker} = Broker.start_link
    broker |> send(:poll)

    assert_receive [:ask, ^test_channel, ^phone_number, ["Do you smoke? Reply 1 for YES, 2 for NO"]]

    survey = Repo.get(Survey, survey.id)
    assert survey.state == "running"

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "active"

    reply = Broker.sync_step(respondent, "Yes")
    assert reply == {:prompt, "Do you exercise? Reply 1 for YES, 2 for NO"}

    respondent = Repo.get(Respondent, respondent.id)
    reply = Broker.sync_step(respondent, "Yes")
    assert reply == {:prompt, "Which is the second perfect number??"}

    respondent = Repo.get(Respondent, respondent.id)
    reply = Broker.sync_step(respondent, "99")
    assert reply == :end

    now = Timex.now
    interval = Interval.new(from: Timex.shift(now, seconds: -5), until: Timex.shift(now, seconds: 5), step: [seconds: 1])

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "completed"
    assert respondent.session == nil
    assert respondent.completed_at in interval
  end

  test "only polls surveys schedule for todays weekday" do
    week_day = Timex.weekday(Timex.today)
    schedule1 = %Ask.DayOfWeek{
      mon: week_day == 1,
      tue: week_day == 2,
      wed: week_day == 3,
      thu: week_day == 4,
      fri: week_day == 5,
      sat: week_day == 6,
      sun: week_day == 7}
    schedule2 = %Ask.DayOfWeek{
      mon: week_day != 1,
      tue: week_day != 2,
      wed: week_day != 3,
      thu: week_day != 4,
      fri: week_day != 5,
      sat: week_day != 6,
      sun: week_day != 7}
    survey1 = insert(:survey, Map.merge(@always_schedule, %{schedule_day_of_week: schedule1, state: "running", timezone: "Etc/UTC"}))
    survey2 = insert(:survey, Map.merge(@always_schedule, %{schedule_day_of_week: schedule2, state: "running", timezone: "Etc/UTC"}))

    Broker.handle_info(:poll, nil)

    survey1 = Repo.get(Survey, survey1.id)
    survey2 = Repo.get(Survey, survey2.id)
    assert survey1.state == "completed"
    assert survey2.state == "running"
  end

  test "doesn't poll surveys with a start time schedule greater than the current hour" do
    now = Timex.now
    ten_oclock = Timex.shift(now, hours: (10-now.hour), minutes: -now.minute)
    eleven_oclock = Timex.add(ten_oclock, Timex.Duration.from_hours(1))
    twelve_oclock = Timex.add(eleven_oclock, Timex.Duration.from_hours(1))
    {:ok, mock_now} = Ecto.Time.cast(ten_oclock)
    {:ok, start_time} = Ecto.Time.cast(eleven_oclock)
    {:ok, end_time} = Ecto.Time.cast(twelve_oclock)
    attrs = %{schedule_start_time: start_time, schedule_end_time: end_time, state: "running"}
    survey = insert(:survey, Map.merge(@always_schedule, attrs))

    Broker.handle_info(:poll, nil, mock_now)

    survey = Repo.get(Survey, survey.id)
    assert survey.state == "running"
  end

  test "doesn't poll surveys with an end time schedule smaller than the current hour" do
    now = Timex.now
    ten_oclock = Timex.shift(now, hours: (10-now.hour), minutes: -now.minute)
    eleven_oclock = Timex.add(ten_oclock, Timex.Duration.from_hours(1))
    twelve_oclock = Timex.add(eleven_oclock, Timex.Duration.from_hours(1))
    {:ok, start_time} = Ecto.Time.cast(ten_oclock)
    {:ok, end_time} = Ecto.Time.cast(eleven_oclock)
    {:ok, mock_now} = Ecto.Time.cast(twelve_oclock)
    attrs = %{schedule_start_time: start_time, schedule_end_time: end_time, state: "running"}
    survey = insert(:survey, Map.merge(@always_schedule, attrs))

    Broker.handle_info(:poll, nil, mock_now)

    survey = Repo.get(Survey, survey.id)
    assert survey.state == "running"
  end

  def create_running_survey_with_channel_and_respondent(steps \\ @dummy_steps) do
    test_channel = TestChannel.new
    channel = insert(:channel, settings: test_channel |> TestChannel.settings)
    quiz = insert(:questionnaire, steps: steps)
    survey = insert(:survey, Map.merge(@always_schedule, %{state: "running", questionnaire: quiz, timezone: "Etc/UTC"})) |> Repo.preload([:channels])
    channel_changeset = Ecto.Changeset.change(channel)
    survey |> Ecto.Changeset.change |> Ecto.Changeset.put_assoc(:channels, [channel_changeset]) |> Repo.update
    respondent = insert(:respondent, survey: survey)
    phone_number = respondent.phone_number

    [survey, test_channel, respondent, phone_number]
  end

  def create_several_respondents(survey, n) when n <= 1 do
    [insert(:respondent, survey: survey)]
  end

  def create_several_respondents(survey, n) do
    [create_several_respondents(survey, n - 1) | insert(:respondent, survey: survey)]
  end

  def assert_respondents_by_state(survey, active, pending) do
    [a, p] = get_respondents_by_state(survey)

    assert a == active
    assert p == pending
  end

  def get_respondents_by_state(survey) do
    by_state = Repo.all(
      from r in assoc(survey, :respondents),
      group_by: :state,
      select: {r.state, count("*")}) |> Enum.into(%{})
    [by_state["active"] || 0, by_state["pending"] || 0]
  end
end
