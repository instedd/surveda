defmodule Ask.BrokerTest do
  use Ask.ModelCase
  use Ask.DummySteps
  use Timex
  alias Ask.Runtime.{Broker, Flow}
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
    survey = insert(:survey, Map.merge(@always_schedule, %{state: "running"}))
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

    now = Timex.now
    interval = Interval.new(from: Timex.shift(now, minutes: 9), until: Timex.shift(now, minutes: 11), step: [seconds: 1])
    assert updated_respondent.timeout_at in interval
  end

  test "retry respondent (SMS mode)" do
    [survey, test_channel, respondent, phone_number] = create_running_survey_with_channel_and_respondent()
    survey |> Survey.changeset(%{sms_retry_configuration: "10m"}) |> Repo.update

    # First poll, activate the respondent
    Broker.handle_info(:poll, nil)
    assert_received [:setup, ^test_channel, %Respondent{sanitized_phone_number: ^phone_number}]
    assert_received [:ask, ^test_channel, ^phone_number, ["Do you smoke? Reply 1 for YES, 2 for NO"]]

    # Set for immediate timeout
    Respondent.changeset(respondent, %{timeout_at: Timex.now |> Timex.shift(minutes: -1)}) |> Repo.update

    # Second poll, retry the question
    Broker.handle_info(:poll, nil)
    refute_received [:setup, _, _]
    assert_received [:ask, ^test_channel, ^phone_number, ["Do you smoke? Reply 1 for YES, 2 for NO"]]

    # Set for immediate timeout
    Respondent.changeset(respondent, %{timeout_at: Timex.now |> Timex.shift(minutes: -1)}) |> Repo.update

    # Third poll, this time it should stall
    Broker.handle_info(:poll, nil)

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "stalled"

    survey = Repo.get(Survey, survey.id)
    assert survey.state == "running"
  end

  test "respondent answers after stalled with active survey" do
    [survey, test_channel, respondent, phone_number] = create_running_survey_with_channel_and_respondent()

    {:ok, _} = Broker.start_link

    # First poll, activate the respondent
    Broker.handle_info(:poll, nil)
    assert_received [:setup, ^test_channel, %Respondent{sanitized_phone_number: ^phone_number}]
    assert_received [:ask, ^test_channel, ^phone_number, ["Do you smoke? Reply 1 for YES, 2 for NO"]]

    # Set for immediate timeout
    Respondent.changeset(respondent, %{timeout_at: Timex.now |> Timex.shift(minutes: -1)}) |> Repo.update

    # This time it should stall
    Broker.handle_info(:poll, nil)

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "stalled"
    survey = Repo.get(Survey, survey.id)
    assert survey.state == "running"

    reply = Broker.sync_step(respondent, Flow.Message.reply("Yes"))
    respondent = Repo.get(Respondent, respondent.id) |> Repo.preload(:responses)
    assert reply == {:prompt, "Do you exercise? Reply 1 for YES, 2 for NO"}
    assert survey.state == "running"
    assert respondent.state == "active"
    assert hd(respondent.responses).value == "Yes"
  end

  test "respondent answers after stalled with completed survey" do
    [survey, _, respondent, _] = create_running_survey_with_channel_and_respondent()
    second_respondent = insert(:respondent, survey: survey)
    Repo.update(survey |> change |> Survey.changeset(%{cutoff: 1}))

    {:ok, _} = Broker.start_link
    Broker.handle_info(:poll, nil)
    respondent = Repo.get(Respondent, respondent.id) |> Repo.preload(:responses)
    assert respondent.state == "active"

    # Set for immediate timeout
    Respondent.changeset(respondent, %{timeout_at: Timex.now |> Timex.shift(minutes: -1)}) |> Repo.update

    Broker.handle_info(:poll, nil)

    respondent = Repo.get(Respondent, respondent.id) |> Repo.preload(:responses)
    second_respondent = Repo.get(Respondent, second_respondent.id) |> Repo.preload(:responses)
    assert respondent.state == "stalled"
    assert second_respondent.state == "active"
    survey = Repo.get(Survey, survey.id)
    assert survey.state == "running"

    Repo.update(second_respondent |> change |> Respondent.changeset(%{state: "completed"}))

    Broker.handle_info(:poll, nil)

    survey = Repo.get(Survey, survey.id)
    assert survey.state == "completed"
    respondent = Repo.get(Respondent, respondent.id) |> Repo.preload(:responses)
    assert respondent.state == "failed"
  end

  test "retry respondent (IVR mode)" do
    [survey, test_channel, respondent, phone_number] = create_running_survey_with_channel_and_respondent(@dummy_steps, "ivr")
    survey |> Survey.changeset(%{ivr_retry_configuration: "10m"}) |> Repo.update

    # First poll, activate the respondent
    Broker.handle_info(:poll, nil)
    assert_received [:setup, ^test_channel, %Respondent{sanitized_phone_number: ^phone_number}]

    # Set for immediate timeout
    Respondent.changeset(respondent, %{timeout_at: Timex.now |> Timex.shift(minutes: -1)}) |> Repo.update

    # Second poll, retry the question
    Broker.handle_info(:poll, nil)
    assert_received [:setup, ^test_channel, %Respondent{sanitized_phone_number: ^phone_number}]

    # Set for immediate timeout
    Respondent.changeset(respondent, %{timeout_at: Timex.now |> Timex.shift(minutes: -1)}) |> Repo.update

    # Third poll, this time it should fail
    Broker.handle_info(:poll, nil)

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "failed"

    survey = Repo.get(Survey, survey.id)
    assert survey.state == "completed"
  end

  test "fallback respondent (SMS => IVR)" do
    test_channel = TestChannel.new(true)
    channel = insert(:channel, settings: test_channel |> TestChannel.settings, type: "sms")

    test_fallback_channel = TestChannel.new(false)
    fallback_channel = insert(:channel, settings: test_fallback_channel |> TestChannel.settings, type: "ivr")

    quiz = insert(:questionnaire, steps: @dummy_steps)
    survey = insert(:survey, Map.merge(@always_schedule, %{state: "running", questionnaire: quiz, mode: ["sms", "ivr"]})) |> Repo.preload([:channels])

    channels_changeset = [Ecto.Changeset.change(channel), Ecto.Changeset.change(fallback_channel)]

    survey |> Ecto.Changeset.change |> Ecto.Changeset.put_assoc(:channels, channels_changeset) |> Repo.update
    respondent = insert(:respondent, survey: survey)
    phone_number = respondent.sanitized_phone_number

    survey |> Survey.changeset(%{sms_retry_configuration: "1m 50m"}) |> Repo.update
    survey |> Survey.changeset(%{ivr_retry_configuration: "20m"}) |> Repo.update

    # First poll, activate the respondent
    Broker.handle_info(:poll, nil)
    assert_received [:setup, ^test_channel, %Respondent{sanitized_phone_number: ^phone_number}]
    assert_received [:ask, ^test_channel, ^phone_number, ["Do you smoke? Reply 1 for YES, 2 for NO"]]

    # Set for immediate timeout
    Respondent.changeset(respondent, %{timeout_at: Timex.now |> Timex.shift(minutes: -1)}) |> Repo.update

    # Second poll, retry the question
    Broker.handle_info(:poll, nil)
    refute_received [:setup, _, _]
    assert_received [:ask, ^test_channel, ^phone_number, ["Do you smoke? Reply 1 for YES, 2 for NO"]]

    # Set for immediate timeout
    Respondent.changeset(respondent, %{timeout_at: Timex.now |> Timex.shift(minutes: -1)}) |> Repo.update

    # Third poll, this time fallback to IVR channel
    Broker.handle_info(:poll, nil)
    assert_received [:setup, ^test_fallback_channel, %Respondent{sanitized_phone_number: ^phone_number}]
  end

  test "fallback respondent (IVR => SMS)" do
    test_channel = TestChannel.new(false)
    channel = insert(:channel, settings: test_channel |> TestChannel.settings, type: "ivr")

    test_fallback_channel = TestChannel.new(true)
    fallback_channel = insert(:channel, settings: test_fallback_channel |> TestChannel.settings, type: "sms")

    quiz = insert(:questionnaire, steps: @dummy_steps)
    survey = insert(:survey, Map.merge(@always_schedule, %{state: "running", questionnaire: quiz, mode: ["ivr", "sms"]})) |> Repo.preload([:channels])

    channels_changeset = [Ecto.Changeset.change(channel), Ecto.Changeset.change(fallback_channel)]

    survey |> Ecto.Changeset.change |> Ecto.Changeset.put_assoc(:channels, channels_changeset) |> Repo.update
    respondent = insert(:respondent, survey: survey)
    phone_number = respondent.sanitized_phone_number

    survey |> Survey.changeset(%{sms_retry_configuration: "10m"}) |> Repo.update
    survey |> Survey.changeset(%{ivr_retry_configuration: "2m 20m"}) |> Repo.update

    # First poll, activate the respondent
    Broker.handle_info(:poll, nil)
    assert_received [:setup, ^test_channel, %Respondent{sanitized_phone_number: ^phone_number}]

    # Set for immediate timeout
    Respondent.changeset(respondent, %{timeout_at: Timex.now |> Timex.shift(minutes: -1)}) |> Repo.update

    # Second poll, retry the question
    Broker.handle_info(:poll, nil)
    assert_received [:setup, ^test_channel, %Respondent{sanitized_phone_number: ^phone_number}]

    # Set for immediate timeout
    Respondent.changeset(respondent, %{timeout_at: Timex.now |> Timex.shift(minutes: -1)}) |> Repo.update

    # Third poll, this time fallback to SMS channel
    Broker.handle_info(:poll, nil)
    assert_received [:setup, ^test_fallback_channel, %Respondent{sanitized_phone_number: ^phone_number}]
    assert_received [:ask, ^test_fallback_channel, ^phone_number, ["Do you smoke? Reply 1 for YES, 2 for NO"]]
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

    assert_respondents_by_state(survey, 10, 6)

    Repo.all(from r in Respondent, where: r.state == "active")
    |> Enum.map(fn respondent ->
      Repo.update(respondent |> change |> Respondent.changeset(%{state: "completed"}))
    end)

    Broker.handle_info(:poll, nil)

    assert_respondents_by_state(survey, 0, 6)

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

    reply = Broker.sync_step(respondent, Flow.Message.reply("Yes"))
    assert reply == {:prompt, "Do you exercise? Reply 1 for YES, 2 for NO"}

    respondent = Repo.get(Respondent, respondent.id)
    reply = Broker.sync_step(respondent, Flow.Message.reply("Yes"))
    assert reply == {:prompt, "Which is the second perfect number??"}

    respondent = Repo.get(Respondent, respondent.id)
    reply = Broker.sync_step(respondent, Flow.Message.reply("99"))
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
    survey1 = insert(:survey, Map.merge(@always_schedule, %{schedule_day_of_week: schedule1, state: "running"}))
    survey2 = insert(:survey, Map.merge(@always_schedule, %{schedule_day_of_week: schedule2, state: "running"}))

    Broker.handle_info(:poll, nil)

    survey1 = Repo.get(Survey, survey1.id)
    survey2 = Repo.get(Survey, survey2.id)
    assert survey1.state == "completed"
    assert survey2.state == "running"
  end

  test "doesn't poll surveys with a start time schedule greater than the current hour" do
    now = Timex.now
    ten_oclock = Timex.shift(now |> Timex.beginning_of_day, hours: 10)
    eleven_oclock = Timex.shift(ten_oclock, hours: 1)
    twelve_oclock = Timex.shift(eleven_oclock, hours: 2)
    {:ok, start_time} = Ecto.Time.cast(eleven_oclock)
    {:ok, end_time} = Ecto.Time.cast(twelve_oclock)
    attrs = %{schedule_start_time: start_time, schedule_end_time: end_time, state: "running"}
    survey = insert(:survey, Map.merge(@always_schedule, attrs))

    Broker.handle_info(:poll, nil, ten_oclock)

    survey = Repo.get(Survey, survey.id)
    assert survey.state == "running"
  end

  test "doesn't poll surveys with an end time schedule smaller than the current hour" do
    now = Timex.now
    ten_oclock = Timex.shift(now |> Timex.beginning_of_day, hours: 10)
    eleven_oclock = Timex.shift(ten_oclock, hours: 1)
    twelve_oclock = Timex.shift(eleven_oclock, hours: 2)
    {:ok, start_time} = Ecto.Time.cast(ten_oclock)
    {:ok, end_time} = Ecto.Time.cast(eleven_oclock)
    attrs = %{schedule_start_time: start_time, schedule_end_time: end_time, state: "running"}
    survey = insert(:survey, Map.merge(@always_schedule, attrs))

    Broker.handle_info(:poll, nil, twelve_oclock)

    survey = Repo.get(Survey, survey.id)
    assert survey.state == "running"
  end

  test "doesn't poll surveys with an end time schedule smaller than the current hour considering timezone" do
    ten_oclock = Timex.parse!("2016-01-01T10:00:00Z", "{ISO:Extended}")
    eleven_oclock = Timex.parse!("2016-01-01T11:00:00Z", "{ISO:Extended}")
    twelve_oclock = Timex.parse!("2016-01-01T12:00:00Z", "{ISO:Extended}")
    {:ok, start_time} = Ecto.Time.cast(ten_oclock)
    mock_now = eleven_oclock
    {:ok, end_time} = Ecto.Time.cast(twelve_oclock)
    attrs = %{schedule_start_time: start_time, schedule_end_time: end_time, state: "running", timezone: "Asia/Shanghai"}
    survey = insert(:survey, Map.merge(@always_schedule, attrs))

    Broker.handle_info(:poll, nil, mock_now)

    survey = Repo.get(Survey, survey.id)
    assert survey.state == "running"
  end

  test "does poll surveys with an end time schedule higher than the current hour considering timezone" do
    ten_oclock = Timex.parse!("2016-01-01T10:00:00Z", "{ISO:Extended}")
    twelve_oclock = Timex.parse!("2016-01-01T12:00:00Z", "{ISO:Extended}")
    two_oclock_pm = Timex.parse!("2016-01-01T14:00:00Z", "{ISO:Extended}")
    {:ok, start_time} = Ecto.Time.cast(ten_oclock)
    mock_now = two_oclock_pm
    {:ok, end_time} = Ecto.Time.cast(twelve_oclock)
    attrs = %{schedule_start_time: start_time, schedule_end_time: end_time, state: "running", timezone: "America/Buenos_Aires"}
    survey = insert(:survey, Map.merge(@always_schedule, attrs))

    Broker.handle_info(:poll, nil, mock_now)

    survey = Repo.get(Survey, survey.id)
    assert survey.state == "completed"
  end

  def create_running_survey_with_channel_and_respondent(steps \\ @dummy_steps, mode \\ "sms") do
    test_channel = TestChannel.new(mode == "sms")
    channel = insert(:channel, settings: test_channel |> TestChannel.settings, type: mode)
    quiz = insert(:questionnaire, steps: steps)
    survey = insert(:survey, Map.merge(@always_schedule, %{state: "running", questionnaire: quiz, mode: [mode]})) |> Repo.preload([:channels])
    channel_changeset = Ecto.Changeset.change(channel)
    survey |> Ecto.Changeset.change |> Ecto.Changeset.put_assoc(:channels, [channel_changeset]) |> Repo.update
    respondent = insert(:respondent, survey: survey)
    phone_number = respondent.sanitized_phone_number

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
