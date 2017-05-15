defmodule Ask.BrokerTest do
  use Ask.ModelCase
  use Ask.DummySteps
  use Timex
  alias Ask.Runtime.{Broker, Flow, SurveyLogger, ReplyHelper}
  alias Ask.{Repo, Survey, Respondent, RespondentDispositionHistory, TestChannel, QuotaBucket, Questionnaire, RespondentGroupChannel}
  require Ask.Runtime.ReplyHelper

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

  test "set as 'completed' when there are no respondents" do
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

  test "set the respondent as completed when the questionnaire is empty" do
    [_, _, _, respondent, _] = create_running_survey_with_channel_and_respondent([])

    Broker.handle_info(:poll, nil)

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "completed"
  end

  test "set the respondent as completed (disposition) when the questionnaire is empty" do
    [_, _, _, respondent, _] = create_running_survey_with_channel_and_respondent([])

    Broker.handle_info(:poll, nil)

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.disposition == "completed"
  end

  test "don't set the respondent as completed (disposition) if disposition is ineligible" do
    [_, _, _, respondent, _] = create_running_survey_with_channel_and_respondent(@ineligible_step)

    Broker.handle_info(:poll, nil)

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.disposition == "ineligible"
  end

  test "don't set the respondent as completed (disposition) if disposition is refused" do
    [_, _, _, respondent, _] = create_running_survey_with_channel_and_respondent(@refused_step)

    Broker.handle_info(:poll, nil)

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.disposition == "refused"
  end

  test "don't set the respondent as partial (disposition) if disposition is ineligible" do
    [_, _, _, respondent, _] = create_running_survey_with_channel_and_respondent(@ineligible_step ++ @partial_step)

    Broker.handle_info(:poll, nil)

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.disposition == "ineligible"
  end

  test "don't set the respondent as partial (disposition) if disposition is refused" do
    [_, _, _, respondent, _] = create_running_survey_with_channel_and_respondent(@refused_step ++ @partial_step)

    Broker.handle_info(:poll, nil)

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.disposition == "refused"
  end

  test "don't set the respondent as ineligible (disposition) if disposition is partial" do
    [_, _, _, respondent, _] =
      create_running_survey_with_channel_and_respondent(@invalid_ineligible_after_partial_steps)

    {:ok, _} = Broker.start_link

    Broker.handle_info(:poll, nil)

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.disposition == "partial"

    reply = Broker.sync_step(respondent, Flow.Message.reply("Yes"))
    assert {:reply, ReplyHelper.simple("Is this the last question?")} = reply

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.disposition == "partial"
  end

  test "don't set the respondent as ineligible (disposition) if disposition is completed" do
    [_, _, _, respondent, _] = create_running_survey_with_channel_and_respondent(@completed_step ++ @ineligible_step)

    Broker.handle_info(:poll, nil)

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.disposition == "completed"
  end

  test "set the respondent as complete (disposition) if disposition is partial" do
    [_, _, _, respondent, _] = create_running_survey_with_channel_and_respondent(@partial_step)

    Broker.handle_info(:poll, nil)

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.disposition == "completed"
  end

  test "creates respondent history when the questionnaire is empty" do
    [_, _, _, respondent, _] = create_running_survey_with_channel_and_respondent([])

    Broker.handle_info(:poll, nil)

    histories = RespondentDispositionHistory |> Repo.all
    assert length(histories) == 2

    history = histories |> Enum.take(-1) |> hd
    assert history.respondent_id == respondent.id
    assert history.disposition == "completed"
    assert history.mode == nil
  end

  test "set the respondent questionnaire and mode" do
    [survey, _, _, respondent, _] = create_running_survey_with_channel_and_respondent([])
    mode = hd(survey.mode)
    questionnaire = hd(survey.questionnaires)

    Broker.handle_info(:poll, nil)

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.mode == mode
    assert respondent.questionnaire_id == questionnaire.id
  end

  test "set the respondent questionnaire and mode with comparisons" do
    test_channel = TestChannel.new
    sms_channel = insert(:channel, settings: test_channel |> TestChannel.settings, type: "sms")
    ivr_channel = insert(:channel, settings: test_channel |> TestChannel.settings, type: "ivr")

    quiz1 = insert(:questionnaire, steps: @dummy_steps)
    quiz2 = insert(:questionnaire, steps: @dummy_steps)
    survey = insert(:survey, Map.merge(@always_schedule, %{
        state: "running",
        questionnaires: [quiz1, quiz2],
        mode: [["sms"], ["ivr"]],
        comparisons: [
          %{"mode" => ["sms"], "questionnaire_id" => quiz1.id, "ratio" => 0},
          %{"mode" => ["sms"], "questionnaire_id" => quiz2.id, "ratio" => 0},
          %{"mode" => ["ivr"], "questionnaire_id" => quiz1.id, "ratio" => 100},
          %{"mode" => ["ivr"], "questionnaire_id" => quiz2.id, "ratio" => 0},
        ]
        }))
    group = insert(:respondent_group, survey: survey, respondents_count: 1) |> Repo.preload(:channels)

    sms_channel_changeset = Ecto.Changeset.change(sms_channel)
    ivr_channel_changeset = Ecto.Changeset.change(ivr_channel)
    group = group |> Ecto.Changeset.change |> Ecto.Changeset.put_assoc(:channels, [sms_channel_changeset, ivr_channel_changeset]) |> Repo.update!

    respondent = insert(:respondent, survey: survey, respondent_group: group)

    Broker.handle_info(:poll, nil)

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.mode == ["ivr"]
    assert respondent.questionnaire_id == quiz1.id
  end

  test "changes the respondent state from pending to running if neccessary" do
    [survey, _, _, respondent, _] = create_running_survey_with_channel_and_respondent()

    Broker.handle_info(:poll, nil)

    survey = Repo.get(Survey, survey.id)
    assert survey.state == "running"
    updated_respondent = Repo.get(Respondent, respondent.id)
    assert updated_respondent.state == "active"

    now = Timex.now
    interval = Interval.new(from: Timex.shift(now, minutes: 9), until: Timex.shift(now, minutes: 11), step: [seconds: 1])
    assert updated_respondent.timeout_at in interval
  end

  test "changes the respondent disposition from registered to queued" do
    [survey, _, _, respondent, _] = create_running_survey_with_channel_and_respondent()

    Broker.handle_info(:poll, nil)

    survey = Repo.get(Survey, survey.id)
    assert survey.state == "running"
    updated_respondent = Repo.get(Respondent, respondent.id)
    assert updated_respondent.disposition == "queued"
  end

  test "changes the respondent disposition from queued to contacted on delivery confirm (SMS)" do
    [_survey, _group, test_channel, respondent, phone_number] = create_running_survey_with_channel_and_respondent()

    {:ok, broker} = Broker.start_link
    Broker.poll

    assert_received [:ask, ^test_channel, %Respondent{sanitized_phone_number: ^phone_number}, _, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")]

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.disposition == "queued"

    Broker.delivery_confirm(respondent, "Do you smoke?")

    updated_respondent = Repo.get(Respondent, respondent.id)
    assert updated_respondent.state == "active"
    assert updated_respondent.disposition == "contacted"

    :ok = broker |> GenServer.stop
  end

  test "changes the respondent disposition from queued to contacted on answer (IVR)" do
    [_survey, _group, _test_channel, respondent, _phone_number] = create_running_survey_with_channel_and_respondent(@dummy_steps, "ivr")

    {:ok, broker} = Broker.start_link
    Broker.poll

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.disposition == "queued"

    reply = Broker.sync_step(respondent, Flow.Message.answer())
    assert {:reply, ReplyHelper.ivr("Do you smoke?", "Do you smoke? Press 8 for YES, 9 for NO")} = reply

    updated_respondent = Repo.get(Respondent, respondent.id)
    assert updated_respondent.state == "active"
    assert updated_respondent.disposition == "contacted"

    :ok = broker |> GenServer.stop
  end

  test "changes the respondent disposition from contacted to started on first answer received" do
    [_survey, _group, test_channel, respondent, phone_number] = create_running_survey_with_channel_and_respondent()

    {:ok, broker} = Broker.start_link
    Broker.poll

    assert_received [:ask, ^test_channel, %Respondent{sanitized_phone_number: ^phone_number}, _, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")]

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.disposition == "queued"

    Broker.delivery_confirm(respondent, "Do you smoke?")

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "active"
    assert respondent.disposition == "contacted"

    Broker.sync_step(respondent, Flow.Message.reply("Yes"))

    updated_respondent = Repo.get(Respondent, respondent.id)
    assert updated_respondent.state == "active"
    assert updated_respondent.disposition == "started"

    :ok = broker |> GenServer.stop
  end

  test "set timeout_at according to retries if they're present" do
    [survey, _, _, respondent, _] = create_running_survey_with_channel_and_respondent()
    survey |> Survey.changeset(%{sms_retry_configuration: "2m"}) |> Repo.update!

    {:ok, _} = Broker.start_link
    Broker.handle_info(:poll, nil)

    respondent = Repo.get(Respondent, respondent.id)
    Broker.sync_step(respondent, Flow.Message.reply("Yes"))

    updated_respondent = Repo.get(Respondent, respondent.id)
    assert updated_respondent.state == "active"

    now = Timex.now
    interval = Interval.new(from: Timex.shift(now, minutes: 1), until: Timex.shift(now, minutes: 3), step: [seconds: 1])
    assert updated_respondent.timeout_at in interval
  end

  test "set timeout_at according to retries, taking survey schedule into account" do
    [survey, _, _, respondent, _] = create_running_survey_with_channel_and_respondent()

    {:ok, _} = Broker.start_link
    Broker.handle_info(:poll, nil)

    survey |> Survey.changeset(%{sms_retry_configuration: "1d", schedule_day_of_week: tomorrow_schedule_day_of_week()}) |> Repo.update!

    respondent = Repo.get(Respondent, respondent.id)
    Broker.sync_step(respondent, Flow.Message.reply("Yes"))

    updated_respondent = Repo.get(Respondent, respondent.id)
    assert updated_respondent.state == "active"

    {erl_date, _} = Timex.now |> Timex.shift(days: 1) |> Timex.to_erl
    time = Timex.Timezone.resolve("Etc/UTC", {erl_date, {0, 0, 0}})
    assert updated_respondent.timeout_at == time
  end

  test "retry respondent (SMS mode)" do
    [survey, _group, test_channel, _respondent, phone_number] = create_running_survey_with_channel_and_respondent()
    survey |> Survey.changeset(%{sms_retry_configuration: "10m"}) |> Repo.update

    # First poll, activate the respondent
    Broker.handle_info(:poll, nil)
    assert_received [:setup, ^test_channel, respondent = %Respondent{sanitized_phone_number: ^phone_number}, token]
    assert_received [:ask, ^test_channel, ^respondent, ^token, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")]

    # Set for immediate timeout
    respondent = Repo.get!(Respondent, respondent.id)
    Respondent.changeset(respondent, %{timeout_at: Timex.now |> Timex.shift(minutes: -1)}) |> Repo.update

    # Second poll, retry the question
    Broker.handle_info(:poll, nil)
    refute_received [:setup, _, _, _, _]
    assert_received [:ask, ^test_channel, %Respondent{sanitized_phone_number: ^phone_number}, _token, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")]

    # Set for immediate timeout
    respondent = Repo.get!(Respondent, respondent.id)
    Respondent.changeset(respondent, %{timeout_at: Timex.now |> Timex.shift(minutes: -1)}) |> Repo.update

    # Third poll, this time it should stall
    Broker.handle_info(:poll, nil)

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "stalled"

    survey = Repo.get(Survey, survey.id)
    assert survey.state == "running"
  end

  test "retry respondent (mobileweb mode)" do
    [survey, _group, test_channel, respondent, phone_number] = create_running_survey_with_channel_and_respondent(@mobileweb_dummy_steps, "mobileweb")
    survey |> Survey.changeset(%{mobileweb_retry_configuration: "10m"}) |> Repo.update

    {:ok, broker} = Broker.start_link
    Broker.poll

    assert_receive [:ask, ^test_channel, %Respondent{sanitized_phone_number: ^phone_number}, _, ReplyHelper.simple("Contact", message)]
    assert message == "Please enter http://app.ask.dev/mobile_survey/#{respondent.id}?token=#{Respondent.token(respondent.id)}"

    survey = Repo.get(Survey, survey.id)
    assert survey.state == "running"

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "active"

    # Set for immediate timeout
    respondent = Repo.get!(Respondent, respondent.id)
    Respondent.changeset(respondent, %{timeout_at: Timex.now |> Timex.shift(minutes: -1)}) |> Repo.update

    # Second poll, retry the question
    Broker.poll
    refute_received [:setup, _, _, _, _]
    assert_receive [:ask, ^test_channel, %Respondent{sanitized_phone_number: ^phone_number}, _, ReplyHelper.simple("Contact", message)]
    assert message == "Please enter http://app.ask.dev/mobile_survey/#{respondent.id}?token=#{Respondent.token(respondent.id)}"

    # Set for immediate timeout
    respondent = Repo.get!(Respondent, respondent.id)
    Respondent.changeset(respondent, %{timeout_at: Timex.now |> Timex.shift(minutes: -1)}) |> Repo.update

    # Third poll, this time it should stall
    Broker.poll

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "stalled"

    survey = Repo.get(Survey, survey.id)
    assert survey.state == "running"

    :ok = broker |> GenServer.stop
  end

  test "respondent answers after stalled with active survey" do
    [survey, _group, test_channel, _respondent, phone_number] = create_running_survey_with_channel_and_respondent()

    {:ok, _} = Broker.start_link

    # First poll, activate the respondent
    Broker.handle_info(:poll, nil)
    assert_received [:setup, ^test_channel, respondent = %Respondent{sanitized_phone_number: ^phone_number}, token]
    assert_received [:ask, ^test_channel, ^respondent, ^token, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")]

    # Set for immediate timeout
    respondent = Repo.get!(Respondent, respondent.id)
    Respondent.changeset(respondent, %{timeout_at: Timex.now |> Timex.shift(minutes: -1)}) |> Repo.update

    # This time it should stall
    Broker.handle_info(:poll, nil)

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "stalled"
    survey = Repo.get(Survey, survey.id)
    assert survey.state == "running"

    reply = Broker.sync_step(respondent, Flow.Message.reply("Yes"))
    respondent = Repo.get(Respondent, respondent.id) |> Repo.preload(:responses)
    assert {:reply, ReplyHelper.simple("Do you exercise", "Do you exercise? Reply 1 for YES, 2 for NO")} = reply
    assert survey.state == "running"
    assert respondent.state == "active"
    assert hd(respondent.responses).value == "Yes"
  end

  test "mark stalled respondent as failed after 8 hours" do
    [_survey, _group, test_channel, _respondent, phone_number] = create_running_survey_with_channel_and_respondent()

    {:ok, _} = Broker.start_link

    # First poll, activate the respondent
    Broker.handle_info(:poll, nil)
    assert_received [:setup, ^test_channel, respondent = %Respondent{sanitized_phone_number: ^phone_number}, token]
    assert_received [:ask, ^test_channel, ^respondent, ^token, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")]

    # Set for immediate timeout
    respondent = Repo.get!(Respondent, respondent.id)
    Respondent.changeset(respondent, %{timeout_at: Timex.now |> Timex.shift(minutes: -1)}) |> Repo.update

    # This time it should stall
    Broker.handle_info(:poll, nil)

    respondent = Repo.get(Respondent, respondent.id)

    now = Timex.now

    # After seven hours it's still stalled
    seven_hours_ago = now |> Timex.shift(hours: -7) |> Timex.to_erl |> Ecto.DateTime.from_erl
    (from r in Respondent, where: r.id == ^respondent.id) |> Repo.update_all(set: [updated_at: seven_hours_ago])

    Broker.handle_info(:poll, nil)

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "stalled"
    assert respondent.disposition == "queued"

    # After eight hours it should be marked as failed
    eight_hours_ago = now |> Timex.shift(hours: -8) |> Timex.to_erl |> Ecto.DateTime.from_erl
    (from r in Respondent, where: r.id == ^respondent.id) |> Repo.update_all(set: [updated_at: eight_hours_ago])

    Broker.handle_info(:poll, nil)

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "failed"
    assert respondent.disposition == "failed"
  end

  test "mark disposition as partial" do
    [survey, _group, test_channel, _respondent, phone_number] = create_running_survey_with_channel_and_respondent(@flag_steps)

    {:ok, _} = Broker.start_link

    # First poll, activate the respondent
    Broker.handle_info(:poll, nil)
    assert_received [:setup, ^test_channel, respondent = %Respondent{sanitized_phone_number: ^phone_number}, token]
    assert_received [:ask, ^test_channel, ^respondent, ^token, ReplyHelper.simple("Do you exercise?", "Do you exercise? Reply 1 for YES, 2 for NO")]

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "active"
    assert respondent.disposition == "partial"
    survey = Repo.get(Survey, survey.id)
    assert survey.state == "running"

    histories = RespondentDispositionHistory |> Repo.all
    assert length(histories) == 2

    history = histories |> Enum.take(-1) |> hd
    assert history.respondent_id == respondent.id
    assert history.disposition == "partial"
    assert history.mode == "sms"
  end

  test "mark disposition as ineligible on end" do
    [_survey, _group, test_channel, _respondent, phone_number] = create_running_survey_with_channel_and_respondent(@flag_steps_ineligible_skip_logic)

    {:ok, _} = Broker.start_link

    # First poll, activate the respondent
    Broker.handle_info(:poll, nil)
    assert_received [:setup, ^test_channel, respondent = %Respondent{sanitized_phone_number: ^phone_number}, token]
    assert_received [:ask, ^test_channel, ^respondent, ^token, ReplyHelper.simple("Do you exercise?", "Do you exercise? Reply 1 for YES, 2 for NO")]

    respondent = Repo.get!(Respondent, respondent.id)
    Broker.delivery_confirm(respondent, "Do you exercise?")
    Broker.sync_step(respondent, Flow.Message.reply("Yes"))

    respondent = Repo.get!(Respondent, respondent.id)
    assert respondent.state == "completed"
    assert respondent.disposition == "ineligible"

    histories = RespondentDispositionHistory |> Repo.all
    assert length(histories) == 4

    history = histories |> Enum.take(-1) |> hd
    assert history.respondent_id == respondent.id
    assert history.disposition == "ineligible"
  end

  test "mark disposition as refused on end" do
    [_survey, _group, test_channel, _respondent, phone_number] = create_running_survey_with_channel_and_respondent(@flag_steps_refused_skip_logic)

    {:ok, _} = Broker.start_link

    # First poll, activate the respondent
    Broker.handle_info(:poll, nil)
    assert_received [:setup, ^test_channel, respondent = %Respondent{sanitized_phone_number: ^phone_number}, token]
    assert_received [:ask, ^test_channel, ^respondent, ^token, ReplyHelper.simple("Do you exercise?", "Do you exercise? Reply 1 for YES, 2 for NO")]

    respondent = Repo.get!(Respondent, respondent.id)
    Broker.sync_step(respondent, Flow.Message.reply("Yes"))

    respondent = Repo.get!(Respondent, respondent.id)
    assert respondent.state == "completed"
    assert respondent.disposition == "refused"

    histories = RespondentDispositionHistory |> Repo.all
    assert length(histories) == 3

    history = histories |> Enum.take(-1) |> hd
    assert history.respondent_id == respondent.id
    assert history.disposition == "refused"
  end

  test "mark disposition as refused and respondent as failed when the respondent sends 'STOP'" do
    [_survey, _group, test_channel, _respondent, phone_number] = create_running_survey_with_channel_and_respondent(@flag_steps_refused_skip_logic)

    {:ok, _} = Broker.start_link

    # First poll, activate the respondent
    Broker.handle_info(:poll, nil)
    assert_received [:setup, ^test_channel, respondent = %Respondent{sanitized_phone_number: ^phone_number}, token]
    assert_received [:ask, ^test_channel, ^respondent, ^token, ReplyHelper.simple("Do you exercise?", "Do you exercise? Reply 1 for YES, 2 for NO")]

    respondent = Repo.get!(Respondent, respondent.id)
    Broker.sync_step(respondent, Flow.Message.reply("StoP"))

    respondent = Repo.get!(Respondent, respondent.id)
    assert respondent.state == "failed"
    assert respondent.disposition == "refused"

    histories = RespondentDispositionHistory |> Repo.all
    assert length(histories) == 3

    history = histories |> Enum.take(-1) |> hd
    assert history.respondent_id == respondent.id
    assert history.disposition == "refused"
  end

  test "mark disposition as completed when partial on end" do
    [_survey, _group, test_channel, _respondent, phone_number] = create_running_survey_with_channel_and_respondent(@flag_steps_partial_skip_logic)

    {:ok, _} = Broker.start_link

    # First poll, activate the respondent
    Broker.handle_info(:poll, nil)
    assert_received [:setup, ^test_channel, respondent = %Respondent{sanitized_phone_number: ^phone_number}, token]
    assert_received [:ask, ^test_channel, ^respondent, ^token, ReplyHelper.simple("Do you exercise?", "Do you exercise? Reply 1 for YES, 2 for NO")]

    respondent = Repo.get!(Respondent, respondent.id)
    Broker.sync_step(respondent, Flow.Message.reply("Yes"))

    respondent = Repo.get!(Respondent, respondent.id)
    assert respondent.state == "completed"
    assert respondent.disposition == "completed"

    histories = RespondentDispositionHistory |> Repo.all
    assert length(histories) == 3

    history = histories |> Enum.take(-1) |> hd
    assert history.respondent_id == respondent.id
    assert history.disposition == "completed"
  end

  test "don't reset disposition after having set it" do
    [survey, _group, test_channel, _respondent, phone_number] = create_running_survey_with_channel_and_respondent(@flag_steps)

    {:ok, _} = Broker.start_link

    # First poll, activate the respondent
    Broker.handle_info(:poll, nil)
    assert_received [:setup, ^test_channel, respondent = %Respondent{sanitized_phone_number: ^phone_number}, token]
    assert_received [:ask, ^test_channel, ^respondent, ^token, ReplyHelper.simple("Do you exercise?", "Do you exercise? Reply 1 for YES, 2 for NO")]

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "active"
    assert respondent.disposition == "partial"
    survey = Repo.get(Survey, survey.id)
    assert survey.state == "running"

    reply = Broker.sync_step(respondent, Flow.Message.reply("Yes"))

    assert {:reply, ReplyHelper.simple("Is this the last question?")} = reply

    respondent = Repo.get(Respondent, respondent.id) |> Repo.preload(:responses)
    assert survey.state == "running"
    assert respondent.state == "active"
    assert respondent.disposition == "partial"
    assert hd(respondent.responses).value == "Yes"
  end

  test "contacted respondents are marked as unresponsive after 8 hours" do
    [survey, _, test_channel, respondent, phone_number] = create_running_survey_with_channel_and_respondent()
    Repo.update(survey |> change |> Survey.changeset(%{cutoff: 1}))

    {:ok, broker} = Broker.start_link
    Broker.poll

    assert_received [:ask, ^test_channel, %Respondent{sanitized_phone_number: ^phone_number}, _, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")]

    survey = Repo.get(Survey, survey.id)
    assert survey.state == "running"
    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "active"
    assert respondent.disposition == "queued"

    Broker.delivery_confirm(respondent, "Do you smoke?")

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.disposition == "contacted"

    now = Timex.now

    # Set for immediate timeout
    Respondent.changeset(respondent, %{timeout_at: now |> Timex.shift(minutes: -1)}) |> Repo.update
    Broker.handle_info(:poll, nil)

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "stalled"
    assert respondent.disposition == "contacted"

    # After eight hours it should be marked as failed
    eight_hours_ago = now |> Timex.shift(hours: -8) |> Timex.to_erl |> Ecto.DateTime.from_erl
    (from r in Respondent, where: r.id == ^respondent.id) |> Repo.update_all(set: [updated_at: eight_hours_ago])

    Broker.handle_info(:poll, nil)

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "failed"
    assert respondent.disposition == "unresponsive"

    :ok = broker |> GenServer.stop
  end

  test "queued respondents are marked failed after 8 hours" do
    [survey, _, test_channel, respondent, phone_number] = create_running_survey_with_channel_and_respondent()
    Repo.update(survey |> change |> Survey.changeset(%{cutoff: 1}))

    {:ok, broker} = Broker.start_link
    Broker.poll

    assert_received [:ask, ^test_channel, %Respondent{sanitized_phone_number: ^phone_number}, _, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")]

    survey = Repo.get(Survey, survey.id)
    assert survey.state == "running"
    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "active"
    assert respondent.disposition == "queued"

    now = Timex.now

    # Set for immediate timeout
    Respondent.changeset(respondent, %{timeout_at: now |> Timex.shift(minutes: -1)}) |> Repo.update
    Broker.handle_info(:poll, nil)

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "stalled"
    assert respondent.disposition == "queued"

    # After eight hours it should be marked as failed
    eight_hours_ago = now |> Timex.shift(hours: -8) |> Timex.to_erl |> Ecto.DateTime.from_erl
    (from r in Respondent, where: r.id == ^respondent.id) |> Repo.update_all(set: [updated_at: eight_hours_ago])

    Broker.handle_info(:poll, nil)

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "failed"
    assert respondent.disposition == "failed"

    :ok = broker |> GenServer.stop
  end

  test "uncontacted respondents are marked as failed after all retries are met (IVR)" do
    [_, _, _, respondent, _] = create_running_survey_with_channel_and_respondent(@dummy_steps, "ivr")
    {:ok, broker} = Broker.start_link
    Broker.poll

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.disposition == "queued"

    # Set for immediate timeout
    Respondent.changeset(respondent, %{timeout_at: Timex.now |> Timex.shift(minutes: -1)}) |> Repo.update
    Broker.handle_info(:poll, nil)

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "failed"
    assert respondent.disposition == "failed"

    :ok = broker |> GenServer.stop
  end

  test "started respondents are marked as breakoff after 8 hours" do
    [survey, _, test_channel, respondent, phone_number] = create_running_survey_with_channel_and_respondent()
    Repo.update(survey |> change |> Survey.changeset(%{cutoff: 1}))

    {:ok, broker} = Broker.start_link
    Broker.poll

    assert_received [:ask, ^test_channel, %Respondent{sanitized_phone_number: ^phone_number}, _, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")]

    survey = Repo.get(Survey, survey.id)
    assert survey.state == "running"
    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "active"
    assert respondent.disposition == "queued"

    Broker.delivery_confirm(respondent, "Do you smoke?")

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "active"
    assert respondent.disposition == "contacted"

    respondent = Repo.get(Respondent, respondent.id)
    Broker.sync_step(respondent, Flow.Message.reply("yes"))

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "active"
    assert respondent.disposition == "started"

    Broker.delivery_confirm(respondent, "Do you exercise?")

    now = Timex.now

    Respondent.changeset(respondent, %{timeout_at: now |> Timex.shift(minutes: -1)}) |> Repo.update
    Broker.handle_info(:poll, nil)

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "stalled"
    assert respondent.disposition == "started"

    # After eight hours it should be marked as failed
    eight_hours_ago = now |> Timex.shift(hours: -8) |> Timex.to_erl |> Ecto.DateTime.from_erl
    (from r in Respondent, where: r.id == ^respondent.id) |> Repo.update_all(set: [updated_at: eight_hours_ago])

    Broker.handle_info(:poll, nil)

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "failed"
    assert respondent.disposition == "breakoff"

    :ok = broker |> GenServer.stop
  end

  test "stalled respondents are marked as failed after survey completes but disposition is kept" do
    [survey, group, test_channel, respondent, phone_number] = create_running_survey_with_channel_and_respondent()
    second_respondent = insert(:respondent, survey: survey, respondent_group: group)
    Repo.update(survey |> change |> Survey.changeset(%{cutoff: 1}))

    {:ok, broker} = Broker.start_link
    Broker.poll

    assert_received [:ask, ^test_channel, %Respondent{sanitized_phone_number: ^phone_number}, _, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")]

    survey = Repo.get(Survey, survey.id)
    assert survey.state == "running"
    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "active"
    assert respondent.disposition == "queued"

    Broker.delivery_confirm(respondent, "Do you smoke?")

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "active"
    assert respondent.disposition == "contacted"

    respondent = Repo.get(Respondent, respondent.id)
    Broker.sync_step(respondent, Flow.Message.reply("yes"))

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "active"
    assert respondent.disposition == "started"

    Broker.delivery_confirm(respondent, "Do you exercise?")

    Respondent.changeset(respondent, %{timeout_at: Timex.now |> Timex.shift(minutes: -1)}) |> Repo.update
    Broker.handle_info(:poll, nil)

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "stalled"
    assert respondent.disposition == "started"

    second_respondent = Repo.get(Respondent, second_respondent.id)
    Repo.update(second_respondent |> change |> Respondent.changeset(%{state: "completed"}))

    Broker.handle_info(:poll, nil)

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "failed"
    assert respondent.disposition == "started"

    :ok = broker |> GenServer.stop
  end

  test "started respondents are marked as breakoff after all retries are met (IVR)" do
    [_, _, _, respondent, _] = create_running_survey_with_channel_and_respondent(@dummy_steps, "ivr")

    {:ok, broker} = Broker.start_link
    Broker.poll

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "active"
    assert respondent.disposition == "queued"

    reply = Broker.sync_step(respondent, Flow.Message.answer())
    assert {:reply, ReplyHelper.ivr("Do you smoke?", "Do you smoke? Press 8 for YES, 9 for NO")} = reply

    respondent = Repo.get(Respondent, respondent.id)
    reply = Broker.sync_step(respondent, Flow.Message.reply("9"))
    assert {:reply, ReplyHelper.ivr("Do you exercise", "Do you exercise? Press 1 for YES, 2 for NO")} = reply

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "active"
    assert respondent.disposition == "started"

    Respondent.changeset(respondent, %{timeout_at: Timex.now |> Timex.shift(minutes: -1)}) |> Repo.update
    Broker.handle_info(:poll, nil)

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "failed"
    assert respondent.disposition == "breakoff"

    :ok = broker |> GenServer.stop
  end

  test "contacted respondents are marked as unresponsive after all retries are met (IVR)" do
    [_, _, _, respondent, _] = create_running_survey_with_channel_and_respondent(@dummy_steps, "ivr")

    {:ok, broker} = Broker.start_link
    Broker.poll

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "active"
    assert respondent.disposition == "queued"

    reply = Broker.sync_step(respondent, Flow.Message.answer())
    assert {:reply, ReplyHelper.ivr("Do you smoke?", "Do you smoke? Press 8 for YES, 9 for NO")} = reply

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "active"
    assert respondent.disposition == "contacted"

    Respondent.changeset(respondent, %{timeout_at: Timex.now |> Timex.shift(minutes: -1)}) |> Repo.update
    Broker.handle_info(:poll, nil)

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "failed"
    assert respondent.disposition == "unresponsive"

    :ok = broker |> GenServer.stop
  end

  test "retry respondent (IVR mode)" do
    [survey, _group, test_channel, respondent, phone_number] = create_running_survey_with_channel_and_respondent(@dummy_steps, "ivr")
    survey |> Survey.changeset(%{ivr_retry_configuration: "10m"}) |> Repo.update

    # First poll, activate the respondent
    Broker.handle_info(:poll, nil)
    assert_received [:setup, ^test_channel, %Respondent{sanitized_phone_number: ^phone_number}, _token]

    # Set for immediate timeout
    respondent = Repo.get(Respondent, respondent.id)
    Respondent.changeset(respondent, %{timeout_at: Timex.now |> Timex.shift(minutes: -1)}) |> Repo.update

    # Second poll, retry the question
    Broker.handle_info(:poll, nil)
    assert_received [:setup, ^test_channel, %Respondent{sanitized_phone_number: ^phone_number}, _token]

    # Set for immediate timeout
    respondent = Repo.get(Respondent, respondent.id)
    Respondent.changeset(respondent, %{timeout_at: Timex.now |> Timex.shift(minutes: -1)}) |> Repo.update

    # Third poll, this time it should fail
    Broker.handle_info(:poll, nil)

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "failed"

    survey = Repo.get(Survey, survey.id)
    assert survey.state == "completed"
  end

  test "fallback respondent (SMS => IVR)" do
    test_channel = TestChannel.new
    channel = insert(:channel, settings: test_channel |> TestChannel.settings, type: "sms")

    test_fallback_channel = TestChannel.new
    fallback_channel = insert(:channel, settings: test_fallback_channel |> TestChannel.settings, type: "ivr")

    quiz = insert(:questionnaire, steps: @dummy_steps)
    survey = insert(:survey, Map.merge(@always_schedule, %{state: "running", questionnaires: [quiz], mode: [["sms", "ivr"]]}))
    group = insert(:respondent_group, survey: survey, respondents_count: 1) |> Repo.preload([:channels])

    RespondentGroupChannel.changeset(%RespondentGroupChannel{}, %{respondent_group_id: group.id, channel_id: channel.id, mode: channel.type}) |> Repo.insert
    RespondentGroupChannel.changeset(%RespondentGroupChannel{}, %{respondent_group_id: group.id, channel_id: fallback_channel.id, mode: fallback_channel.type}) |> Repo.insert

    respondent = insert(:respondent, survey: survey, respondent_group: group)
    phone_number = respondent.sanitized_phone_number

    survey |> Survey.changeset(%{sms_retry_configuration: "1m 50m"}) |> Repo.update!
    survey |> Survey.changeset(%{ivr_retry_configuration: "20m"}) |> Repo.update!

    # First poll, activate the respondent
    Broker.handle_info(:poll, nil)
    assert_received [:setup, ^test_channel, respondent = %Respondent{sanitized_phone_number: ^phone_number}, token]
    assert_received [:ask, ^test_channel, ^respondent, ^token, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")]

    # Set for immediate timeout
    respondent = Repo.get(Respondent, respondent.id)
    Respondent.changeset(respondent, %{timeout_at: Timex.now |> Timex.shift(minutes: -1)}) |> Repo.update

    # Second poll, retry the question
    Broker.handle_info(:poll, nil)
    refute_received [:setup, _, _, _, _]
    assert_received [:ask, ^test_channel, %Respondent{sanitized_phone_number: ^phone_number}, _token, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")]

    # Set for immediate timeout
    respondent = Repo.get(Respondent, respondent.id)
    Respondent.changeset(respondent, %{timeout_at: Timex.now |> Timex.shift(minutes: -1)}) |> Repo.update

    # Third poll, retry the question
    Broker.handle_info(:poll, nil)
    refute_received [:setup, _, _, _, _]
    assert_received [:ask, ^test_channel, %Respondent{sanitized_phone_number: ^phone_number}, _token, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")]

    # Set for immediate timeout
    respondent = Repo.get(Respondent, respondent.id)
    Respondent.changeset(respondent, %{timeout_at: Timex.now |> Timex.shift(minutes: -1)}) |> Repo.update

    # Fourth poll, this time fallback to IVR channel
    Broker.handle_info(:poll, nil)
    assert_received [:setup, ^test_fallback_channel, %Respondent{sanitized_phone_number: ^phone_number}, _token]
  end

  test "fallback respondent (IVR => SMS)" do
    test_channel = TestChannel.new
    channel = insert(:channel, settings: test_channel |> TestChannel.settings, type: "ivr")

    test_fallback_channel = TestChannel.new
    fallback_channel = insert(:channel, settings: test_fallback_channel |> TestChannel.settings, type: "sms")

    quiz = insert(:questionnaire, steps: @dummy_steps)
    survey = insert(:survey, Map.merge(@always_schedule, %{state: "running", questionnaires: [quiz], mode: [["ivr", "sms"]]}))
    group = insert(:respondent_group, survey: survey, respondents_count: 1) |> Repo.preload([:channels])

    RespondentGroupChannel.changeset(%RespondentGroupChannel{}, %{respondent_group_id: group.id, channel_id: channel.id, mode: channel.type}) |> Repo.insert
    RespondentGroupChannel.changeset(%RespondentGroupChannel{}, %{respondent_group_id: group.id, channel_id: fallback_channel.id, mode: fallback_channel.type}) |> Repo.insert

    respondent = insert(:respondent, survey: survey, respondent_group: group)
    phone_number = respondent.sanitized_phone_number

    survey |> Survey.changeset(%{sms_retry_configuration: "10m"}) |> Repo.update!
    survey |> Survey.changeset(%{ivr_retry_configuration: "2m 20m"}) |> Repo.update!

    # First poll, activate the respondent
    Broker.handle_info(:poll, nil)
    assert_received [:setup, ^test_channel, %Respondent{sanitized_phone_number: ^phone_number}, _token]

    # Set for immediate timeout
    respondent = Repo.get(Respondent, respondent.id)
    Respondent.changeset(respondent, %{timeout_at: Timex.now |> Timex.shift(minutes: -1)}) |> Repo.update

    # Second poll, retry the question
    Broker.handle_info(:poll, nil)
    assert_received [:setup, ^test_channel, %Respondent{sanitized_phone_number: ^phone_number}, _token]

    # Set for immediate timeout
    respondent = Repo.get(Respondent, respondent.id)
    Respondent.changeset(respondent, %{timeout_at: Timex.now |> Timex.shift(minutes: -1)}) |> Repo.update

    # Third poll, this time fallback to SMS channel
    Broker.handle_info(:poll, nil)
    assert_received [:setup, ^test_channel, %Respondent{sanitized_phone_number: ^phone_number}, _token]

    # Set for immediate timeout
    respondent = Repo.get(Respondent, respondent.id)
    Respondent.changeset(respondent, %{timeout_at: Timex.now |> Timex.shift(minutes: -1)}) |> Repo.update

    # Fourth poll, this time fallback to SMS channel
    Broker.handle_info(:poll, nil)
    assert_received [:setup, ^test_fallback_channel, respondent = %Respondent{sanitized_phone_number: ^phone_number}, token]
    assert_received [:ask, ^test_fallback_channel, ^respondent, ^token, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")]
  end

  test "should not keep setting pending to actives when cutoff is reached" do
    [survey, group, _, _, _] = create_running_survey_with_channel_and_respondent()
    create_several_respondents(survey, group, 20)

    Repo.update(survey |> change |> Survey.changeset(%{cutoff: 1}))

    Broker.handle_info(:poll, nil)

    survey = Repo.get(Survey, survey.id)
    assert_respondents_by_state(survey, 1, 20)

    r = Repo.all(from r in Respondent, where: r.state == "active") |> hd
    Repo.update(r |> change |> Respondent.changeset(%{state: "completed"}))

    Broker.handle_info(:poll, nil)

    assert_respondents_by_state(survey, 0, 20)
    assert survey.state == "running"
  end

  test "marks survey as complete when the cutoff is reached and actives become stalled" do
    [survey, group, _, _, _] = create_running_survey_with_channel_and_respondent()
    create_several_respondents(survey, group, 20)

    Repo.update(survey |> change |> Survey.changeset(%{cutoff: 1}))

    Broker.handle_info(:poll, nil)

    survey = Repo.get(Survey, survey.id)
    assert_respondents_by_state(survey, 1, 20)

    r = Repo.all(from r in Respondent, where: r.state == "active") |> hd
    Repo.update(r |> change |> Respondent.changeset(%{state: "completed"}))

    Repo.all(from r in Respondent, where: r.state == "active")
    |> Enum.map(fn respondent ->
      Repo.update(respondent |> change |> Respondent.changeset(%{state: "stalled"}))
    end)

    Broker.handle_info(:poll, nil)

    survey = Repo.get(Survey, survey.id)

    assert_respondents_by_state(survey, 0, 20)
    assert survey.state == "completed"
  end

  test "marks survey as complete when the cutoff is reached and actives become failed" do
    [survey, group, _, _, _] = create_running_survey_with_channel_and_respondent()
    create_several_respondents(survey, group, 20)

    Repo.update(survey |> change |> Survey.changeset(%{cutoff: 1}))

    Broker.handle_info(:poll, nil)

    survey = Repo.get(Survey, survey.id)
    assert_respondents_by_state(survey, 1, 20)

    r = Repo.all(from r in Respondent, where: r.state == "active") |> hd
    Repo.update(r |> change |> Respondent.changeset(%{state: "completed"}))

    Repo.all(from r in Respondent, where: r.state == "active")
    |> Enum.map(fn respondent ->
      Repo.update(respondent |> change |> Respondent.changeset(%{state: "failed"}))
    end)

    Broker.handle_info(:poll, nil)

    survey = Repo.get(Survey, survey.id)

    assert_respondents_by_state(survey, 0, 20)
    assert survey.state == "completed"
  end

  test "marks the survey as completed when the cutoff is reached and actives become completed" do
    [survey, group, _, _, _] = create_running_survey_with_channel_and_respondent()
    create_several_respondents(survey, group, 20)

    Repo.update(survey |> change |> Survey.changeset(%{cutoff: 6}))

    Broker.handle_info(:poll, nil)

    survey = Repo.get(Survey, survey.id)

    assert survey.state == "running"

    assert_respondents_by_state(survey, 6, 15)

    Repo.all(from r in Respondent, where: r.state == "active", limit: 5)
    |> Enum.map(fn respondent ->
      Repo.update(respondent |> change |> Respondent.changeset(%{state: "completed"}))
    end)

    Broker.handle_info(:poll, nil)

    assert_respondents_by_state(survey, 1, 15)

    Repo.all(from r in Respondent, where: r.state == "active")
    |> Enum.map(fn respondent ->
      Repo.update(respondent |> change |> Respondent.changeset(%{state: "completed"}))
    end)

    Broker.handle_info(:poll, nil)

    assert_respondents_by_state(survey, 0, 15)

    survey = Repo.get(Survey, survey.id)

    assert survey.state == "completed"
  end

  test "marks the survey as completed when all the quotas are reached and actives become completed" do
    [survey, group, _, _, _] = create_running_survey_with_channel_and_respondent()
    create_several_respondents(survey, group, 10)

    quotas = %{
      "vars" => ["Smokes", "Exercises"],
      "buckets" => [
        %{
          "condition" => [%{"store" => "Smokes", "value" => "No"}, %{"store" => "Exercises", "value" => "No"}],
          "quota" => 1,
          "count" => 0
        },
        %{
          "condition" => [%{"store" => "Smokes", "value" => "No"}, %{"store" => "Exercises", "value" => "Yes"}],
          "quota" => 2,
          "count" => 0
        },
        %{
          "condition" => [%{"store" => "Smokes", "value" => "Yes"}, %{"store" => "Exercises", "value" => "No"}],
          "quota" => 3,
          "count" => 0
        },
        %{
          "condition" => [%{"store" => "Smokes", "value" => "Yes"}, %{"store" => "Exercises", "value" => "Yes"}],
          "quota" => 4,
          "count" => 0
        },
      ]
    }

    survey = survey
    |> Repo.preload([:quota_buckets])
    |> Survey.changeset(%{quotas: quotas})
    |> Repo.update!

    qb1 = (from q in QuotaBucket, where: q.quota == 1) |> Repo.one
    qb2 = (from q in QuotaBucket, where: q.quota == 2) |> Repo.one
    qb3 = (from q in QuotaBucket, where: q.quota == 3) |> Repo.one
    qb4 = (from q in QuotaBucket, where: q.quota == 4) |> Repo.one

    Broker.handle_info(:poll, nil)

    # In the beginning it shouldn't be completed
    survey = Survey |> Repo.get(survey.id)
    assert survey.state == "running"

    # Not yet completed: missing fourth bucket
    qb1 |> QuotaBucket.changeset(%{count: 1}) |> Repo.update!
    qb2 |> QuotaBucket.changeset(%{count: 2}) |> Repo.update!
    qb3 |> QuotaBucket.changeset(%{count: 3}) |> Repo.update!
    qb4 |> QuotaBucket.changeset(%{count: 3}) |> Repo.update!
    Broker.handle_info(:poll, nil)

    survey = Survey |> Repo.get(survey.id)
    assert survey.state == "running"

    # Now it should be completed
    qb4 |> QuotaBucket.changeset(%{count: 4}) |> Repo.update!

    Repo.all(from r in Respondent, where: r.state == "active")
    |> Enum.map(fn respondent ->
      Repo.update(respondent |> change |> Respondent.changeset(%{state: "completed"}))
    end)

    Broker.handle_info(:poll, nil)

    survey_id = survey.id
    from q in QuotaBucket,
      where: q.survey_id == ^survey_id

    survey = Survey |> Repo.get(survey.id)
    assert survey.state == "completed"
  end

  test "should not keep setting pending to actives when all the quotas are completed" do
    [survey, group, _, _, _] = create_running_survey_with_channel_and_respondent()
    create_several_respondents(survey, group, 20)

    quotas = %{
      "vars" => ["Smokes", "Exercises"],
      "buckets" => [
        %{
          "condition" => [%{"store" => "Smokes", "value" => "No"}, %{"store" => "Exercises", "value" => "No"}],
          "quota" => 1,
          "count" => 0
        },
        %{
          "condition" => [%{"store" => "Smokes", "value" => "No"}, %{"store" => "Exercises", "value" => "Yes"}],
          "quota" => 2,
          "count" => 0
        },
        %{
          "condition" => [%{"store" => "Smokes", "value" => "Yes"}, %{"store" => "Exercises", "value" => "No"}],
          "quota" => 3,
          "count" => 0
        },
        %{
          "condition" => [%{"store" => "Smokes", "value" => "Yes"}, %{"store" => "Exercises", "value" => "Yes"}],
          "quota" => 4,
          "count" => 0
        },
      ]
    }

    survey = survey
    |> Repo.preload([:quota_buckets])
    |> Survey.changeset(%{quotas: quotas})
    |> Repo.update!

    qb1 = (from q in QuotaBucket, where: q.quota == 1) |> Repo.one
    qb2 = (from q in QuotaBucket, where: q.quota == 2) |> Repo.one
    qb3 = (from q in QuotaBucket, where: q.quota == 3) |> Repo.one
    qb4 = (from q in QuotaBucket, where: q.quota == 4) |> Repo.one

    Broker.handle_info(:poll, nil)

    survey = Survey |> Repo.get(survey.id)
    assert survey.state == "running"

    qb1 |> QuotaBucket.changeset(%{count: 1}) |> Repo.update!
    qb2 |> QuotaBucket.changeset(%{count: 2}) |> Repo.update!
    qb3 |> QuotaBucket.changeset(%{count: 3}) |> Repo.update!
    qb4 |> QuotaBucket.changeset(%{count: 4}) |> Repo.update!

    Repo.all(from r in Respondent, where: r.state == "active", limit: 5)
    |> Enum.map(fn respondent ->
      Repo.update(respondent |> change |> Respondent.changeset(%{state: "completed"}))
    end)

    Broker.handle_info(:poll, nil)

    survey = Survey |> Repo.get(survey.id)
    assert_respondents_by_state(survey, 5, 11)
  end

  test "marks the survey as completed when all the quotas are reached and actives become stalled" do
    [survey, group, _, _, _] = create_running_survey_with_channel_and_respondent()
    create_several_respondents(survey, group, 20)

    quotas = %{
      "vars" => ["Smokes", "Exercises"],
      "buckets" => [
        %{
          "condition" => [%{"store" => "Smokes", "value" => "No"}, %{"store" => "Exercises", "value" => "No"}],
          "quota" => 1,
          "count" => 0
        },
        %{
          "condition" => [%{"store" => "Smokes", "value" => "No"}, %{"store" => "Exercises", "value" => "Yes"}],
          "quota" => 2,
          "count" => 0
        },
        %{
          "condition" => [%{"store" => "Smokes", "value" => "Yes"}, %{"store" => "Exercises", "value" => "No"}],
          "quota" => 3,
          "count" => 0
        },
        %{
          "condition" => [%{"store" => "Smokes", "value" => "Yes"}, %{"store" => "Exercises", "value" => "Yes"}],
          "quota" => 4,
          "count" => 0
        },
      ]
    }

    survey = survey
    |> Repo.preload([:quota_buckets])
    |> Survey.changeset(%{quotas: quotas})
    |> Repo.update!

    qb1 = (from q in QuotaBucket, where: q.quota == 1) |> Repo.one
    qb2 = (from q in QuotaBucket, where: q.quota == 2) |> Repo.one
    qb3 = (from q in QuotaBucket, where: q.quota == 3) |> Repo.one
    qb4 = (from q in QuotaBucket, where: q.quota == 4) |> Repo.one

    Broker.handle_info(:poll, nil)

    survey = Survey |> Repo.get(survey.id)
    assert survey.state == "running"

    qb1 |> QuotaBucket.changeset(%{count: 1}) |> Repo.update!
    qb2 |> QuotaBucket.changeset(%{count: 2}) |> Repo.update!
    qb3 |> QuotaBucket.changeset(%{count: 3}) |> Repo.update!
    qb4 |> QuotaBucket.changeset(%{count: 4}) |> Repo.update!

    Repo.all(from r in Respondent, where: r.state == "active")
    |> Enum.map(fn respondent ->
      Repo.update(respondent |> change |> Respondent.changeset(%{state: "stalled"}))
    end)

    Broker.handle_info(:poll, nil)

    survey = Survey |> Repo.get(survey.id)
    assert_respondents_by_state(survey, 0, 11)
    assert survey.state == "completed"
  end

  test "marks the survey as completed when all the quotas are reached and actives become failed" do
    [survey, group, _, _, _] = create_running_survey_with_channel_and_respondent()
    create_several_respondents(survey, group, 20)

    quotas = %{
      "vars" => ["Smokes", "Exercises"],
      "buckets" => [
        %{
          "condition" => [%{"store" => "Smokes", "value" => "No"}, %{"store" => "Exercises", "value" => "No"}],
          "quota" => 1,
          "count" => 0
        },
        %{
          "condition" => [%{"store" => "Smokes", "value" => "No"}, %{"store" => "Exercises", "value" => "Yes"}],
          "quota" => 2,
          "count" => 0
        },
        %{
          "condition" => [%{"store" => "Smokes", "value" => "Yes"}, %{"store" => "Exercises", "value" => "No"}],
          "quota" => 3,
          "count" => 0
        },
        %{
          "condition" => [%{"store" => "Smokes", "value" => "Yes"}, %{"store" => "Exercises", "value" => "Yes"}],
          "quota" => 4,
          "count" => 0
        },
      ]
    }

    survey = survey
    |> Repo.preload([:quota_buckets])
    |> Survey.changeset(%{quotas: quotas})
    |> Repo.update!

    qb1 = (from q in QuotaBucket, where: q.quota == 1) |> Repo.one
    qb2 = (from q in QuotaBucket, where: q.quota == 2) |> Repo.one
    qb3 = (from q in QuotaBucket, where: q.quota == 3) |> Repo.one
    qb4 = (from q in QuotaBucket, where: q.quota == 4) |> Repo.one

    Broker.handle_info(:poll, nil)

    survey = Survey |> Repo.get(survey.id)
    assert survey.state == "running"

    qb1 |> QuotaBucket.changeset(%{count: 1}) |> Repo.update!
    qb2 |> QuotaBucket.changeset(%{count: 2}) |> Repo.update!
    qb3 |> QuotaBucket.changeset(%{count: 3}) |> Repo.update!
    qb4 |> QuotaBucket.changeset(%{count: 4}) |> Repo.update!

    Repo.all(from r in Respondent, where: r.state == "active")
    |> Enum.map(fn respondent ->
      Repo.update(respondent |> change |> Respondent.changeset(%{state: "failed"}))
    end)

    Broker.handle_info(:poll, nil)

    survey = Survey |> Repo.get(survey.id)
    assert_respondents_by_state(survey, 0, 11)
    assert survey.state == "completed"
  end

  test "always keeps batch_size number of respondents running" do
    [survey, group, _, _, _] = create_running_survey_with_channel_and_respondent()
    create_several_respondents(survey, group, 20)

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

  test "when a survey has any target of completed respondents the batch size depends on the success rate" do
    [survey, group, _, _, _] = create_running_survey_with_channel_and_respondent()
    create_several_respondents(survey, group, 200)

    Repo.update(survey |> change |> Survey.changeset(%{cutoff: 50}))

    Broker.handle_info(:poll, nil)
    assert_respondents_by_state(survey, 50, 151)

    mark_n_active_respondents_as("failed", 20)
    mark_n_active_respondents_as("completed", 30)
    Broker.handle_info(:poll, nil)
    assert_respondents_by_state(survey, 26, 125)

    # since all the previous ones failed the success rate decreases
    # and the batch size increases
    mark_n_active_respondents_as("failed", 26)
    Broker.handle_info(:poll, nil)
    assert_respondents_by_state(survey, 31, 94)
  end

  test "changes running survey state to 'completed' when there are no more running respondents" do
    [survey, _, _, respondent, _] = create_running_survey_with_channel_and_respondent()

    Broker.handle_info(:poll, nil)

    assert_respondents_by_state(survey, 1, 0)

    respondent = Repo.get(Respondent, respondent.id)
    Repo.update(respondent |> change |> Respondent.changeset(%{state: "failed"}))

    Broker.handle_info(:poll, nil)

    survey = Repo.get(Survey, survey.id)

    assert survey.state == "completed"
  end

  test "respondent flow via sms" do
    [survey, _group, test_channel, respondent, phone_number] = create_running_survey_with_channel_and_respondent()

    {:ok, logger} = SurveyLogger.start_link
    {:ok, broker} = Broker.start_link
    Broker.poll

    assert_received [:ask, ^test_channel, %Respondent{sanitized_phone_number: ^phone_number}, _, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")]

    survey = Repo.get(Survey, survey.id)
    assert survey.state == "running"

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "active"

    Broker.delivery_confirm(respondent, "Do you smoke?")

    reply = Broker.sync_step(respondent, Flow.Message.reply("Yes"))
    assert {:reply, ReplyHelper.simple("Do you exercise", "Do you exercise? Reply 1 for YES, 2 for NO")} = reply

    respondent = Repo.get(Respondent, respondent.id)
    Broker.delivery_confirm(respondent, "Do you exercise")

    reply = Broker.sync_step(respondent, Flow.Message.reply("Yes"))
    assert {:reply, ReplyHelper.simple("Which is the second perfect number?", "Which is the second perfect number??")} = reply

    respondent = Repo.get(Respondent, respondent.id)
    Broker.delivery_confirm(respondent, "Which is the second perfect number?")

    reply = Broker.sync_step(respondent, Flow.Message.reply("99"))
    assert {:reply, ReplyHelper.simple("What's the number of this question?", "What's the number of this question??")} = reply

    respondent = Repo.get(Respondent, respondent.id)
    Broker.delivery_confirm(respondent, "What's the number of this question?")

    reply = Broker.sync_step(respondent, Flow.Message.reply("11"))
    assert {:end, {:reply, ReplyHelper.simple("Thank you", "Thanks for completing this survey")}} = reply

    now = Timex.now
    interval = Interval.new(from: Timex.shift(now, seconds: -5), until: Timex.shift(now, seconds: 5), step: [seconds: 1])

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "completed"
    assert respondent.session == nil
    assert respondent.completed_at in interval

    :ok = logger |> GenServer.stop

    assert [do_you_smoke, do_smoke, do_you_exercise, do_exercise, second_perfect_number, ninety_nine, question_number, eleven] = (respondent |> Repo.preload(:survey_log_entries)).survey_log_entries

    assert do_you_smoke.survey_id == survey.id
    assert do_you_smoke.action_data == "Do you smoke?"
    assert do_you_smoke.action_type == "prompt"

    assert do_smoke.survey_id == survey.id
    assert do_smoke.action_data == "Yes"
    assert do_smoke.action_type == "response"

    assert do_you_exercise.survey_id == survey.id
    assert do_you_exercise.action_data == "Do you exercise"
    assert do_you_exercise.action_type == "prompt"

    assert do_exercise.survey_id == survey.id
    assert do_exercise.action_data == "Yes"
    assert do_exercise.action_type == "response"

    assert second_perfect_number.survey_id == survey.id
    assert second_perfect_number.action_data == "Which is the second perfect number?"
    assert second_perfect_number.action_type == "prompt"

    assert ninety_nine.survey_id == survey.id
    assert ninety_nine.action_data == "99"
    assert ninety_nine.action_type == "response"

    assert question_number.survey_id == survey.id
    assert question_number.action_data == "What's the number of this question?"
    assert question_number.action_type == "prompt"

    assert eleven.survey_id == survey.id
    assert eleven.action_data == "11"
    assert eleven.action_type == "response"

    :ok = broker |> GenServer.stop
  end

  test "respondent flow via ivr" do
    [survey, _group, _test_channel, respondent, _phone_number] = create_running_survey_with_channel_and_respondent(@dummy_steps, "ivr")

    {:ok, logger} = SurveyLogger.start_link
    {:ok, broker} = Broker.start_link
    Broker.poll

    survey = Repo.get(Survey, survey.id)
    assert survey.state == "running"

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "active"

    reply = Broker.sync_step(respondent, Flow.Message.answer())
    assert {:reply, ReplyHelper.ivr("Do you smoke?", "Do you smoke? Press 8 for YES, 9 for NO")} = reply

    respondent = Repo.get(Respondent, respondent.id)
    reply = Broker.sync_step(respondent, Flow.Message.reply("9"))
    assert {:reply, ReplyHelper.ivr("Do you exercise", "Do you exercise? Press 1 for YES, 2 for NO")} = reply

    respondent = Repo.get(Respondent, respondent.id)
    reply = Broker.sync_step(respondent, Flow.Message.reply("1"))
    assert {:reply, ReplyHelper.ivr("Which is the second perfect number?", "Which is the second perfect number")} = reply

    respondent = Repo.get(Respondent, respondent.id)
    reply = Broker.sync_step(respondent, Flow.Message.reply("99"))
    assert {:reply, ReplyHelper.ivr("What's the number of this question?", "What's the number of this question")} = reply

    respondent = Repo.get(Respondent, respondent.id)
    reply = Broker.sync_step(respondent, Flow.Message.reply("11"))
    assert {:end, {:reply, ReplyHelper.ivr("Thank you", "Thanks for completing this survey (ivr)")}} = reply

    now = Timex.now
    interval = Interval.new(from: Timex.shift(now, seconds: -5), until: Timex.shift(now, seconds: 5), step: [seconds: 1])

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "completed"
    assert respondent.session == nil
    assert respondent.completed_at in interval

    :ok = logger |> GenServer.stop

    assert [answer, do_you_smoke, do_smoke, do_you_exercise, do_exercise, second_perfect_number, ninety_nine, question_number, eleven] = (respondent |> Repo.preload(:survey_log_entries)).survey_log_entries

    assert answer.survey_id == survey.id
    assert answer.action_data == "Answer"
    assert answer.action_type == "contact"

    assert do_you_smoke.survey_id == survey.id
    assert do_you_smoke.action_data == "Do you smoke?"
    assert do_you_smoke.action_type == "prompt"

    assert do_smoke.survey_id == survey.id
    assert do_smoke.action_data == "9"
    assert do_smoke.action_type == "response"

    assert do_you_exercise.survey_id == survey.id
    assert do_you_exercise.action_data == "Do you exercise"
    assert do_you_exercise.action_type == "prompt"

    assert do_exercise.survey_id == survey.id
    assert do_exercise.action_data == "1"
    assert do_exercise.action_type == "response"

    assert second_perfect_number.survey_id == survey.id
    assert second_perfect_number.action_data == "Which is the second perfect number?"
    assert second_perfect_number.action_type == "prompt"

    assert ninety_nine.survey_id == survey.id
    assert ninety_nine.action_data == "99"
    assert ninety_nine.action_type == "response"

    assert question_number.survey_id == survey.id
    assert question_number.action_data == "What's the number of this question?"
    assert question_number.action_type == "prompt"

    assert eleven.survey_id == survey.id
    assert eleven.action_data == "11"
    assert eleven.action_type == "response"

    :ok = broker |> GenServer.stop
  end

  test "respondent flow via mobileweb" do
    [survey, _group, test_channel, respondent, phone_number] = create_running_survey_with_channel_and_respondent(@mobileweb_dummy_steps, "mobileweb")

    {:ok, broker} = Broker.start_link
    Broker.poll

    assert_receive [:ask, ^test_channel, %Respondent{sanitized_phone_number: ^phone_number}, _, ReplyHelper.simple("Contact", message)]
    assert message == "Please enter http://app.ask.dev/mobile_survey/#{respondent.id}?token=#{Respondent.token(respondent.id)}"

    survey = Repo.get(Survey, survey.id)
    assert survey.state == "running"

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "active"

    reply = Broker.sync_step(respondent, Flow.Message.answer())
    assert {:reply, ReplyHelper.simple("Let there be rock", "Welcome to the survey!")} = reply

    reply = Broker.sync_step(respondent, Flow.Message.answer())
    assert {:reply, ReplyHelper.simple("Let there be rock", "Welcome to the survey!")} = reply

    reply = Broker.sync_step(respondent, Flow.Message.answer())
    assert {:reply, ReplyHelper.simple("Let there be rock", "Welcome to the survey!")} = reply

    respondent = Repo.get(Respondent, respondent.id)
    reply = Broker.sync_step(respondent, Flow.Message.reply(""))
    assert {:reply, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")} = reply

    respondent = Repo.get(Respondent, respondent.id)
    reply = Broker.sync_step(respondent, Flow.Message.reply("Yes"))
    assert {:reply, ReplyHelper.simple("Do you exercise", "Do you exercise? Reply 1 for YES, 2 for NO")} = reply

    respondent = Repo.get(Respondent, respondent.id)
    reply = Broker.sync_step(respondent, Flow.Message.reply("Yes"))
    assert {:reply, ReplyHelper.simple("Which is the second perfect number?", "Which is the second perfect number??")} = reply

    respondent = Repo.get(Respondent, respondent.id)
    reply = Broker.sync_step(respondent, Flow.Message.reply("99"))
    assert {:reply, ReplyHelper.simple("What's the number of this question?", "What's the number of this question??")} = reply

    respondent = Repo.get(Respondent, respondent.id)
    reply = Broker.sync_step(respondent, Flow.Message.reply("11"))
    assert {:end, {:reply, ReplyHelper.simple("Thank you", "Thanks for completing this survey (mobileweb)")}} = reply

    now = Timex.now
    interval = Interval.new(from: Timex.shift(now, seconds: -5), until: Timex.shift(now, seconds: 5), step: [seconds: 1])

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "completed"
    assert respondent.session == nil
    assert respondent.completed_at in interval

    :ok = broker |> GenServer.stop
  end

  test "respondent flow via mobileweb with splitted message" do
    [survey, _group, test_channel, respondent, phone_number] = create_running_survey_with_channel_and_respondent(@mobileweb_dummy_steps, "mobileweb")

    quiz = hd(survey.questionnaires)
    quiz |> Questionnaire.changeset(%{settings: %{"mobile_web_sms_message" => "One#{Questionnaire.sms_split_separator}Two"}}) |> Repo.update!

    {:ok, _} = Broker.start_link
    Broker.poll

    assert_receive [:ask, ^test_channel, %Respondent{sanitized_phone_number: ^phone_number}, _, %Ask.Runtime.Reply{steps: [step]}]
    assert step == Ask.Runtime.ReplyStep.new(["One", "Two http://app.ask.dev/mobile_survey/#{respondent.id}?token=#{Respondent.token(respondent.id)}"], "Contact")
  end

  test "respondent flow with error msg and quota completed msg via sms" do
    [survey, _group, test_channel, respondent, phone_number] = create_running_survey_with_channel_and_respondent()

    quotas = %{
      "vars" => ["Smokes"],
      "buckets" => [
        %{
          "condition" => [%{"store" => "Smokes", "value" => "No"}],
          "quota" => 1,
          "count" => 1
        },
        %{
          "condition" => [%{"store" => "Smokes", "value" => "Yes"}],
          "quota" => 1,
          "count" => 0
        },
      ]
    }

    survey
    |> Repo.preload([:quota_buckets])
    |> Survey.changeset(%{quotas: quotas})
    |> Repo.update!


    quiz = hd((survey |> Ask.Repo.preload(:questionnaires)).questionnaires)
    quiz
    |> Questionnaire.changeset(%{
      quota_completed_steps: [%{
        "id" => "quota-completed-step",
        "type" => "explanation",
        "title" => "Completed",
        "prompt" => %{
          "en" => %{
            "sms" => "Quota completed",
            "ivr" => %{
              "audio_source" => "tts",
              "text" => "Quota completed (ivr)"
            }
          }
        },
        "skip_logic" => nil
      }],
      settings: %{
        "error_message" => %{"en" => %{"sms" => "Wrong answer"}}
      }
    })
    |> Repo.update!

    {:ok, logger} = SurveyLogger.start_link
    {:ok, broker} = Broker.start_link
    Broker.poll

    assert_received [:ask, ^test_channel, %Respondent{sanitized_phone_number: ^phone_number}, _token, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")]

    respondent = Repo.get(Respondent, respondent.id)
    Broker.delivery_confirm(respondent, "Do you smoke?")

    survey = Repo.get(Survey, survey.id)
    assert survey.state == "running"

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "active"
    reply = Broker.sync_step(respondent, Flow.Message.reply("Foo"))
    assert {:reply, ReplyHelper.error("Wrong answer", "Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")} = reply

    respondent = Repo.get(Respondent, respondent.id)
    Broker.delivery_confirm(respondent, "Error")
    Broker.delivery_confirm(respondent, "Do you smoke?")

    reply = Broker.sync_step(respondent, Flow.Message.reply("No"))
    assert {:end, {:reply, ReplyHelper.simple("Completed", "Quota completed")}} = reply

    respondent = Repo.get(Respondent, respondent.id)
    Broker.delivery_confirm(respondent, "Completed")

    :ok = logger |> GenServer.stop

    assert [do_you_smoke, foo, wrong_answer, do_you_smoke_again, dont_smoke] = (respondent |> Repo.preload(:survey_log_entries)).survey_log_entries

    assert do_you_smoke.survey_id == survey.id
    assert do_you_smoke.action_data == "Do you smoke?"
    assert do_you_smoke.action_type == "prompt"

    assert foo.survey_id == survey.id
    assert foo.action_data == "Foo"
    assert foo.action_type == "response"

    assert wrong_answer.survey_id == survey.id
    assert wrong_answer.action_data == "Error"
    assert wrong_answer.action_type == "prompt"

    assert do_you_smoke_again.survey_id == survey.id
    assert do_you_smoke_again.action_data == "Do you smoke?"
    assert do_you_smoke_again.action_type == "prompt"

    assert dont_smoke.survey_id == survey.id
    assert dont_smoke.action_data == "No"
    assert dont_smoke.action_type == "response"

    :ok = broker |> GenServer.stop
  end

  test "respondent flow with error msg and quota completed msg via ivr" do
    [survey, _group, _test_channel, respondent, _phone_number] = create_running_survey_with_channel_and_respondent(@dummy_steps, "ivr")

    quotas = %{
      "vars" => ["Smokes"],
      "buckets" => [
        %{
          "condition" => [%{"store" => "Smokes", "value" => "No"}],
          "quota" => 1,
          "count" => 1
        },
        %{
          "condition" => [%{"store" => "Smokes", "value" => "Yes"}],
          "quota" => 1,
          "count" => 0
        },
      ]
    }

    survey
    |> Repo.preload([:quota_buckets])
    |> Survey.changeset(%{quotas: quotas})
    |> Repo.update!


    quiz = hd((survey |> Ask.Repo.preload(:questionnaires)).questionnaires)
    quiz
    |> Questionnaire.changeset(%{
      quota_completed_steps: [%{
        "id" => "quota-completed-step",
        "type" => "explanation",
        "title" => "Completed",
        "prompt" => %{
          "en" => %{
            "sms" => "Quota completed",
            "ivr" => %{
              "audio_source" => "tts",
              "text" => "Quota completed (ivr)"
            }
          }
        },
        "skip_logic" => nil
      }],
      settings: %{
        "error_message" => %{"en" => %{"ivr" => %{"text" => "Wrong answer", "audio_source" => "tts"}}}
      }
    })
    |> Repo.update!

    {:ok, logger} = SurveyLogger.start_link
    {:ok, broker} = Broker.start_link
    Broker.poll

    survey = Repo.get(Survey, survey.id)
    assert survey.state == "running"

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "active"

    reply = Broker.sync_step(respondent, Flow.Message.answer())
    assert {:reply, ReplyHelper.ivr("Do you smoke?", "Do you smoke? Press 8 for YES, 9 for NO")} = reply

    respondent = Repo.get(Respondent, respondent.id)
    reply = Broker.sync_step(respondent, Flow.Message.reply("3"))
    assert {:reply, ReplyHelper.error_ivr("Wrong answer", "Do you smoke?", "Do you smoke? Press 8 for YES, 9 for NO")} = reply

    respondent = Repo.get(Respondent, respondent.id)
    reply = Broker.sync_step(respondent, Flow.Message.reply("9"))
    assert {:end, {:reply, ReplyHelper.ivr("Completed", "Quota completed (ivr)")}} = reply

    :ok = logger |> GenServer.stop

    assert [answer, do_you_smoke, foo, wrong_answer, do_you_smoke_again, dont_smoke] = (respondent |> Repo.preload(:survey_log_entries)).survey_log_entries

    assert answer.survey_id == survey.id
    assert answer.action_data == "Answer"
    assert answer.action_type == "contact"

    assert do_you_smoke.survey_id == survey.id
    assert do_you_smoke.action_data == "Do you smoke?"
    assert do_you_smoke.action_type == "prompt"

    assert foo.survey_id == survey.id
    assert foo.action_data == "3"
    assert foo.action_type == "response"

    assert wrong_answer.survey_id == survey.id
    assert wrong_answer.action_data == "Error"
    assert wrong_answer.action_type == "prompt"

    assert do_you_smoke_again.survey_id == survey.id
    assert do_you_smoke_again.action_data == "Do you smoke?"
    assert do_you_smoke_again.action_type == "prompt"

    assert dont_smoke.survey_id == survey.id
    assert dont_smoke.action_data == "9"
    assert dont_smoke.action_type == "response"

    :ok = broker |> GenServer.stop
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

  test "does poll surveys considering day of week according to timezone" do
    # Survey runs on Wednesday on every hour, Mexico time (GMT-5)
    attrs = %{
      schedule_day_of_week: %Ask.DayOfWeek{wed: true},
      schedule_start_time: elem(Ecto.Time.cast("00:00:00"), 1),
      schedule_end_time: elem(Ecto.Time.cast("23:59:00"), 1),
      state: "running",
      timezone: "America/Mexico_City",
    }
    survey = insert(:survey, attrs)

    # Now is Thursday 1AM UTC, so in Mexico it's still Wednesday
    mock_now = Timex.parse!("2017-04-27T01:00:00Z", "{ISO:Extended}")

    Broker.handle_info(:poll, nil, mock_now)

    # The survey should have run and be completed (questionnaire is empty)
    survey = Repo.get(Survey, survey.id)
    assert survey.state == "completed"
  end

  test "doesn't poll surveys considering day of week according to timezone" do
    # Survey runs on Wednesday on every hour, Mexico time (GMT-5)
    attrs = %{
      schedule_day_of_week: %Ask.DayOfWeek{wed: true},
      schedule_start_time: elem(Ecto.Time.cast("00:00:00"), 1),
      schedule_end_time: elem(Ecto.Time.cast("23:59:00"), 1),
      state: "running",
      timezone: "America/Mexico_City",
    }
    survey = insert(:survey, attrs)

    # Now is Thursday 6AM UTC, so in Mexico it's now Thursday
    mock_now = Timex.parse!("2017-04-27T06:00:00Z", "{ISO:Extended}")

    Broker.handle_info(:poll, nil, mock_now)

    # Survey shouldn't have started yet
    survey = Repo.get(Survey, survey.id)
    assert survey.state == "running"
  end

  test "increments quota bucket when a respondent completes the survey" do
    [survey, _group, test_channel, respondent, phone_number] = create_running_survey_with_channel_and_respondent()
    Survey.changeset(survey, %{quota_vars: ["Exercises", "Smokes"]}) |> Repo.update()

    selected_bucket = insert(:quota_bucket, survey: survey, condition: %{Smokes: "No", Exercises: "Yes"}, quota: 10, count: 0)
    insert(:quota_bucket, survey: survey, condition: %{Smokes: "No", Exercises: "No"}, quota: 10, count: 0)
    insert(:quota_bucket, survey: survey, condition: %{Smokes: "Yes", Exercises: "Yes"}, quota: 10, count: 0)
    insert(:quota_bucket, survey: survey, condition: %{Smokes: "Yes", Exercises: "No"}, quota: 10, count: 0)

    {:ok, broker} = Broker.start_link
    Broker.poll

    assert_received [:ask, ^test_channel, %Respondent{sanitized_phone_number: ^phone_number}, _token, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")]

    respondent = Repo.get(Respondent, respondent.id)

    reply = Broker.sync_step(respondent, Flow.Message.reply("No"))
    assert {:reply, ReplyHelper.simple("Do you exercise", "Do you exercise? Reply 1 for YES, 2 for NO")} = reply

    respondent = Repo.get(Respondent, respondent.id)
    reply = Broker.sync_step(respondent, Flow.Message.reply("Yes"))
    assert {:reply, ReplyHelper.simple("Which is the second perfect number?", "Which is the second perfect number??")} = reply

    respondent = Repo.get(Respondent, respondent.id)
    reply = Broker.sync_step(respondent, Flow.Message.reply("99"))
    assert {:reply, ReplyHelper.simple("What's the number of this question?", "What's the number of this question??")} = reply

    respondent = Repo.get(Respondent, respondent.id)
    reply = Broker.sync_step(respondent, Flow.Message.reply("11"))
    assert {:end, {:reply, ReplyHelper.simple("Thank you", "Thanks for completing this survey")}} = reply

    selected_bucket = QuotaBucket |> Repo.get(selected_bucket.id)
    assert selected_bucket.count == 1
    assert QuotaBucket
           |> Repo.all
           |> Enum.filter( fn (b) -> b.id != selected_bucket.id end)
           |> Enum.all?( fn (b) -> b.count == 0 end)
    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.disposition == "completed"

    :ok = broker |> GenServer.stop
  end

  test "increments quota bucket when a respondent completes the survey, with numeric condition" do
    [survey, _group, test_channel, respondent, phone_number] = create_running_survey_with_channel_and_respondent()
    Survey.changeset(survey, %{quota_vars: ["Exercises", "Smokes"]}) |> Repo.update()

    insert(:quota_bucket, survey: survey, condition: %{:Smokes => "No", :"Perfect Number" => [20, 30]}, quota: 10, count: 0)
    selected_bucket = insert(:quota_bucket, survey: survey, condition: %{:Smokes => "No", :"Perfect Number" => [31, 40]}, quota: 10, count: 0)
    insert(:quota_bucket, survey: survey, condition: %{:Smokes => "Yes", :"Perfect Number" => [20, 30]}, quota: 10, count: 0)
    insert(:quota_bucket, survey: survey, condition: %{:Smokes => "Yes", :"Perfect Number" => [31, 40]}, quota: 10, count: 0)

    {:ok, broker} = Broker.start_link
    Broker.poll

    assert_received [:ask, ^test_channel, %Respondent{sanitized_phone_number: ^phone_number}, _token, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")]

    respondent = Repo.get(Respondent, respondent.id)

    reply = Broker.sync_step(respondent, Flow.Message.reply("No"))
    assert {:reply, ReplyHelper.simple("Do you exercise", "Do you exercise? Reply 1 for YES, 2 for NO")} = reply

    respondent = Repo.get(Respondent, respondent.id)
    reply = Broker.sync_step(respondent, Flow.Message.reply("Yes"))
    assert {:reply, ReplyHelper.simple("Which is the second perfect number?", "Which is the second perfect number??")} = reply

    respondent = Repo.get(Respondent, respondent.id)
    reply = Broker.sync_step(respondent, Flow.Message.reply("33"))
    assert {:reply, ReplyHelper.simple("What's the number of this question?", "What's the number of this question??")} = reply

    respondent = Repo.get(Respondent, respondent.id)
    reply = Broker.sync_step(respondent, Flow.Message.reply("11"))
    assert {:end, {:reply, ReplyHelper.simple("Thank you", "Thanks for completing this survey")}} = reply

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.disposition == "completed"
    selected_bucket = QuotaBucket |> Repo.get(selected_bucket.id)
    assert selected_bucket.count == 1
    assert QuotaBucket
           |> Repo.all
           |> Enum.filter( fn (b) -> b.id != selected_bucket.id end)
           |> Enum.all?( fn (b) -> b.count == 0 end)

    :ok = broker |> GenServer.stop
  end

  test "marks the respondent as rejected when the bucket is completed" do
    [survey, _group, test_channel, respondent, phone_number] = create_running_survey_with_channel_and_respondent()
    Survey.changeset(survey, %{quota_vars: ["Exercises"]}) |> Repo.update()

    selected_bucket = insert(:quota_bucket, survey: survey, condition: %{:Exercises => "Yes"}, quota: 1, count: 1)
    insert(:quota_bucket, survey: survey, condition: %{:Exercises => "No"}, quota: 10, count: 0)

    {:ok, broker} = Broker.start_link
    Broker.poll

    assert_received [:ask, ^test_channel, %Respondent{sanitized_phone_number: ^phone_number}, _token, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")]

    respondent = Repo.get(Respondent, respondent.id)

    reply = Broker.sync_step(respondent, Flow.Message.reply("No"))
    assert {:reply, ReplyHelper.simple("Do you exercise", "Do you exercise? Reply 1 for YES, 2 for NO")} = reply

    respondent = Repo.get(Respondent, respondent.id)
    reply = Broker.sync_step(respondent, Flow.Message.reply("Yes"))
    assert :end = reply
    updated_respondent = Repo.get(Respondent, respondent.id)
    assert updated_respondent.state == "rejected"
    assert updated_respondent.disposition == "rejected"

    selected_bucket = QuotaBucket |> Repo.get(selected_bucket.id)
    assert selected_bucket.count == 1

    :ok = broker |> GenServer.stop
  end

  test "increments quota bucket when a respondent is flagged as completed" do
    [survey, _group, test_channel, respondent, phone_number] = create_running_survey_with_channel_and_respondent(@dummy_steps_with_flag)
    Survey.changeset(survey, %{quota_vars: ["Exercises", "Smokes"]}) |> Repo.update()

    selected_bucket = insert(:quota_bucket, survey: survey, condition: %{Smokes: "No", Exercises: "Yes"}, quota: 10, count: 0)
    insert(:quota_bucket, survey: survey, condition: %{Smokes: "No", Exercises: "No"}, quota: 10, count: 0)
    insert(:quota_bucket, survey: survey, condition: %{Smokes: "Yes", Exercises: "Yes"}, quota: 10, count: 0)
    insert(:quota_bucket, survey: survey, condition: %{Smokes: "Yes", Exercises: "No"}, quota: 10, count: 0)

    {:ok, broker} = Broker.start_link
    Broker.poll

    assert_received [:ask, ^test_channel, %Respondent{sanitized_phone_number: ^phone_number}, _token, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")]

    respondent = Repo.get(Respondent, respondent.id)

    reply = Broker.sync_step(respondent, Flow.Message.reply("No"))
    assert {:reply, ReplyHelper.simple("Do you exercise", "Do you exercise? Reply 1 for YES, 2 for NO")} = reply

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.disposition == "partial"

    respondent = Repo.get(Respondent, respondent.id)
    reply = Broker.sync_step(respondent, Flow.Message.reply("Yes"))
    assert {:reply, ReplyHelper.simple("Which is the second perfect number?", "Which is the second perfect number??")} = reply

    selected_bucket = QuotaBucket |> Repo.get(selected_bucket.id)
    assert selected_bucket.count == 1
    assert QuotaBucket
           |> Repo.all
           |> Enum.filter( fn (b) -> b.id != selected_bucket.id end)
           |> Enum.all?( fn (b) -> b.count == 0 end)
    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.disposition == "completed"

    respondent = Repo.get(Respondent, respondent.id)
    reply = Broker.sync_step(respondent, Flow.Message.reply("99"))
    assert {:reply, ReplyHelper.simple("What's the number of this question?", "What's the number of this question??")} = reply

    selected_bucket = QuotaBucket |> Repo.get(selected_bucket.id)
    assert selected_bucket.count == 1
    assert QuotaBucket
           |> Repo.all
           |> Enum.filter( fn (b) -> b.id != selected_bucket.id end)
           |> Enum.all?( fn (b) -> b.count == 0 end)
    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.disposition == "completed"

    respondent = Repo.get(Respondent, respondent.id)
    reply = Broker.sync_step(respondent, Flow.Message.reply("11"))
    assert {:end, {:reply, ReplyHelper.simple("Thank you", "Thanks for completing this survey")}} = reply

    selected_bucket = QuotaBucket |> Repo.get(selected_bucket.id)
    assert selected_bucket.count == 1
    assert QuotaBucket
           |> Repo.all
           |> Enum.filter( fn (b) -> b.id != selected_bucket.id end)
           |> Enum.all?( fn (b) -> b.count == 0 end)
    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.disposition == "completed"

    :ok = broker |> GenServer.stop
  end

  test "increments quota bucket when a respondent is flagged as completed, with a numeric condition defining the bucket after the flag was already specified" do
    [survey, _group, test_channel, respondent, phone_number] = create_running_survey_with_channel_and_respondent(@dummy_steps_with_flag)
    Survey.changeset(survey, %{quota_vars: ["Exercises", "Smokes"]}) |> Repo.update()

    insert(:quota_bucket, survey: survey, condition: %{:Smokes => "No", :"Perfect Number" => [20, 30]}, quota: 10, count: 0)
    selected_bucket = insert(:quota_bucket, survey: survey, condition: %{:Smokes => "No", :"Perfect Number" => [31, 40]}, quota: 10, count: 0)
    insert(:quota_bucket, survey: survey, condition: %{:Smokes => "Yes", :"Perfect Number" => [20, 30]}, quota: 10, count: 0)
    insert(:quota_bucket, survey: survey, condition: %{:Smokes => "Yes", :"Perfect Number" => [31, 40]}, quota: 10, count: 0)

    {:ok, broker} = Broker.start_link
    Broker.poll

    assert_received [:ask, ^test_channel, %Respondent{sanitized_phone_number: ^phone_number}, _token, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")]

    respondent = Repo.get(Respondent, respondent.id)

    reply = Broker.sync_step(respondent, Flow.Message.reply("No"))
    assert {:reply, ReplyHelper.simple("Do you exercise", "Do you exercise? Reply 1 for YES, 2 for NO")} = reply

    respondent = Repo.get(Respondent, respondent.id)
    reply = Broker.sync_step(respondent, Flow.Message.reply("Yes"))
    assert {:reply, ReplyHelper.simple("Which is the second perfect number?", "Which is the second perfect number??")} = reply

    respondent = Repo.get(Respondent, respondent.id)
    reply = Broker.sync_step(respondent, Flow.Message.reply("33"))
    assert {:reply, ReplyHelper.simple("What's the number of this question?", "What's the number of this question??")} = reply

    respondent = Repo.get(Respondent, respondent.id)
    reply = Broker.sync_step(respondent, Flow.Message.reply("11"))
    assert {:end, {:reply, ReplyHelper.simple("Thank you", "Thanks for completing this survey")}} = reply

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.disposition == "completed"
    selected_bucket = QuotaBucket |> Repo.get(selected_bucket.id)
    assert selected_bucket.count == 1
    assert QuotaBucket
           |> Repo.all
           |> Enum.filter( fn (b) -> b.id != selected_bucket.id end)
           |> Enum.all?( fn (b) -> b.count == 0 end)

    :ok = broker |> GenServer.stop
  end

  test "increments quota bucket when a respondent is flagged as partial" do
    test_channel = TestChannel.new
    channel = insert(:channel, settings: test_channel |> TestChannel.settings, type: "sms")
    quiz = insert(:questionnaire, steps: @dummy_steps_with_flag)
    survey = insert(:survey, Map.merge(@always_schedule, %{state: "running", questionnaires: [quiz], mode: [["sms"]], count_partial_results: true}))
    group = insert(:respondent_group, survey: survey, respondents_count: 1) |> Repo.preload(:channels)

    RespondentGroupChannel.changeset(%RespondentGroupChannel{}, %{respondent_group_id: group.id, channel_id: channel.id, mode: channel.type}) |> Repo.insert

    respondent = insert(:respondent, survey: survey, respondent_group: group)
    phone_number = respondent.sanitized_phone_number

    Survey.changeset(survey, %{quota_vars: ["Smokes"]}) |> Repo.update()

    selected_bucket = insert(:quota_bucket, survey: survey, condition: %{Smokes: "No"}, quota: 10, count: 0)
    insert(:quota_bucket, survey: survey, condition: %{Smokes: "Yes"}, quota: 10, count: 0)

    {:ok, broker} = Broker.start_link
    Broker.poll

    assert_received [:ask, ^test_channel, %Respondent{sanitized_phone_number: ^phone_number}, _token, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")]

    respondent = Repo.get(Respondent, respondent.id)
    Broker.delivery_confirm(respondent, "Do you smoke?")

    respondent = Repo.get(Respondent, respondent.id)
    reply = Broker.sync_step(respondent, Flow.Message.reply("No"))
    assert {:reply, ReplyHelper.simple("Do you exercise", "Do you exercise? Reply 1 for YES, 2 for NO")} = reply

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.disposition == "partial"

    selected_bucket = QuotaBucket |> Repo.get(selected_bucket.id)
    assert selected_bucket.count == 1
    assert QuotaBucket
           |> Repo.all
           |> Enum.filter( fn (b) -> b.id != selected_bucket.id end)
           |> Enum.all?( fn (b) -> b.count == 0 end)

    respondent = Repo.get(Respondent, respondent.id)
    reply = Broker.sync_step(respondent, Flow.Message.reply("Yes"))
    assert {:reply, ReplyHelper.simple("Which is the second perfect number?", "Which is the second perfect number??")} = reply

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.disposition == "completed"

    respondent = Repo.get(Respondent, respondent.id)
    reply = Broker.sync_step(respondent, Flow.Message.reply("99"))
    assert {:reply, ReplyHelper.simple("What's the number of this question?", "What's the number of this question??")} = reply

    selected_bucket = QuotaBucket |> Repo.get(selected_bucket.id)
    assert selected_bucket.count == 1
    assert QuotaBucket
           |> Repo.all
           |> Enum.filter( fn (b) -> b.id != selected_bucket.id end)
           |> Enum.all?( fn (b) -> b.count == 0 end)
    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.disposition == "completed"

    respondent = Repo.get(Respondent, respondent.id)
    reply = Broker.sync_step(respondent, Flow.Message.reply("11"))
    assert {:end, {:reply, ReplyHelper.simple("Thank you", "Thanks for completing this survey")}} = reply

    selected_bucket = QuotaBucket |> Repo.get(selected_bucket.id)
    assert selected_bucket.count == 1
    assert QuotaBucket
           |> Repo.all
           |> Enum.filter( fn (b) -> b.id != selected_bucket.id end)
           |> Enum.all?( fn (b) -> b.count == 0 end)
    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.disposition == "completed"

    :ok = broker |> GenServer.stop
  end

  test "increments quota bucket when a respondent is flagged as partial before being in a bucket" do
    test_channel = TestChannel.new
    channel = insert(:channel, settings: test_channel |> TestChannel.settings, type: "sms")
    quiz = insert(:questionnaire, steps: @dummy_steps_with_flag)
    survey = insert(:survey, Map.merge(@always_schedule, %{state: "running", questionnaires: [quiz], mode: [["sms"]], count_partial_results: true}))
    group = insert(:respondent_group, survey: survey, respondents_count: 1) |> Repo.preload(:channels)

    RespondentGroupChannel.changeset(%RespondentGroupChannel{}, %{respondent_group_id: group.id, channel_id: channel.id, mode: channel.type}) |> Repo.insert

    respondent = insert(:respondent, survey: survey, respondent_group: group)
    phone_number = respondent.sanitized_phone_number

    Survey.changeset(survey, %{quota_vars: ["Exercises"]}) |> Repo.update()

    selected_bucket = insert(:quota_bucket, survey: survey, condition: %{Exercises: "Yes"}, quota: 10, count: 0)
    insert(:quota_bucket, survey: survey, condition: %{Exercises: "No"}, quota: 10, count: 0)

    {:ok, broker} = Broker.start_link
    Broker.poll

    assert_received [:ask, ^test_channel, %Respondent{sanitized_phone_number: ^phone_number}, _token, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")]

    respondent = Repo.get(Respondent, respondent.id)
    reply = Broker.sync_step(respondent, Flow.Message.reply("No"))
    respondent = Repo.get(Respondent, respondent.id)

    assert {:reply, ReplyHelper.simple("Do you exercise", "Do you exercise? Reply 1 for YES, 2 for NO")} = reply

    assert respondent.disposition == "partial"

    reply = Broker.sync_step(respondent, Flow.Message.reply("Yes"))

    assert {:reply, ReplyHelper.simple("Which is the second perfect number?", "Which is the second perfect number??")} = reply
    respondent = Repo.get(Respondent, respondent.id)
    selected_bucket = QuotaBucket |> Repo.get(selected_bucket.id)

    assert selected_bucket.count == 1
    assert QuotaBucket
           |> Repo.all
           |> Enum.filter( fn (b) -> b.id != selected_bucket.id end)
           |> Enum.all?( fn (b) -> b.count == 0 end)
    assert respondent.disposition == "completed"

    respondent = Repo.get(Respondent, respondent.id)
    reply = Broker.sync_step(respondent, Flow.Message.reply("99"))
    assert {:reply, ReplyHelper.simple("What's the number of this question?", "What's the number of this question??")} = reply

    selected_bucket = QuotaBucket |> Repo.get(selected_bucket.id)
    assert selected_bucket.count == 1
    assert QuotaBucket
           |> Repo.all
           |> Enum.filter( fn (b) -> b.id != selected_bucket.id end)
           |> Enum.all?( fn (b) -> b.count == 0 end)
    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.disposition == "completed"

    respondent = Repo.get(Respondent, respondent.id)
    reply = Broker.sync_step(respondent, Flow.Message.reply("11"))
    assert {:end, {:reply, ReplyHelper.simple("Thank you", "Thanks for completing this survey")}} = reply

    selected_bucket = QuotaBucket |> Repo.get(selected_bucket.id)
    assert selected_bucket.count == 1
    assert QuotaBucket
           |> Repo.all
           |> Enum.filter( fn (b) -> b.id != selected_bucket.id end)
           |> Enum.all?( fn (b) -> b.count == 0 end)
    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.disposition == "completed"

    :ok = broker |> GenServer.stop
  end

  test "doesn't stop survey when there's an uncaught exception" do
    # First, we create a quiz with a single step with an invalid skip_logic value for the "Yes" choice
    step = Ask.StepBuilder
      .multiple_choice_step(
        id: "bbb",
        title: "Do you exercise",
        prompt: Ask.StepBuilder.prompt(
          sms: Ask.StepBuilder.sms_prompt("Do you exercise? Reply 1 for YES, 2 for NO")
        ),
        store: "Exercises",
        choices: [
          Ask.StepBuilder.choice(value: "Yes", responses: Ask.StepBuilder.responses(sms: ["Yes", "Y", "1"], ivr: ["1"]), skip_logic: ""),
          Ask.StepBuilder.choice(value: "No", responses: Ask.StepBuilder.responses(sms: ["No", "N", "2"], ivr: ["2"]))
        ]
      )

    [survey, _group, test_channel, respondent, phone_number] = create_running_survey_with_channel_and_respondent([step])

    {:ok, broker} = Broker.start_link
    Broker.poll

    assert_received [:ask, ^test_channel, %Respondent{sanitized_phone_number: ^phone_number}, _token, ReplyHelper.simple("Do you exercise", "Do you exercise? Reply 1 for YES, 2 for NO")]

    respondent = Repo.get(Respondent, respondent.id)

    # Respondent says 1 (i.e.: Yes), causing an invalid skip_logic to be inspected
    Broker.sync_step(respondent, Flow.Message.reply("1"))

    # If there's a probelm with one respondent, continue the survey with others
    # and mark this one as failed
    survey = Repo.get(Survey, survey.id)
    assert survey.state == "running"

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "failed"

    :ok = broker |> GenServer.stop
  end

  test "reloads respondent if stale" do
    [survey, _, _, respondent, _] = create_running_survey_with_channel_and_respondent()
    survey |> Survey.changeset(%{sms_retry_configuration: "2m"}) |> Repo.update!

    {:ok, _} = Broker.start_link
    Broker.handle_info(:poll, nil)

    respondent = Repo.get(Respondent, respondent.id)
    session = respondent.session |> Ask.Runtime.Session.load
    Broker.retry_respondent(respondent)

    Broker.sync_step_internal(session, Flow.Message.reply("Yes"))

    updated_respondent = Repo.get(Respondent, respondent.id)
    assert updated_respondent.state == "active"

    now = Timex.now
    interval = Interval.new(from: Timex.shift(now, minutes: 9), until: Timex.shift(now, minutes: 11), step: [seconds: 1])
    assert updated_respondent.timeout_at in interval
  end

  test "marks as failed after 3 successive wrong replies" do
    [_, _, _, respondent, _] = create_running_survey_with_channel_and_respondent()

    {:ok, _} = Broker.start_link
    Broker.handle_info(:poll, nil)

    (1..3) |> Enum.each(fn _ ->
      respondent = Repo.get(Respondent, respondent.id)
      Broker.sync_step(respondent, Flow.Message.reply("Oops"))
    end)

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "failed"
    assert respondent.disposition == "breakoff"
  end

  test "reply via another channel (sms when ivr is the current one)" do
    sms_test_channel = TestChannel.new(false, true)
    sms_channel = insert(:channel, settings: sms_test_channel |> TestChannel.settings, type: "sms")

    ivr_test_channel = TestChannel.new(false, false)
    ivr_channel = insert(:channel, settings: ivr_test_channel |> TestChannel.settings, type: "ivr")

    quiz = insert(:questionnaire, steps: @dummy_steps)
    survey = insert(:survey, Map.merge(@always_schedule, %{state: "running", questionnaires: [quiz], mode: [["ivr", "sms"]]}))
    group = insert(:respondent_group, survey: survey, respondents_count: 1) |> Repo.preload(:channels)

    RespondentGroupChannel.changeset(%RespondentGroupChannel{}, %{respondent_group_id: group.id, channel_id: sms_channel.id, mode: "sms"}) |> Repo.insert
    RespondentGroupChannel.changeset(%RespondentGroupChannel{}, %{respondent_group_id: group.id, channel_id: ivr_channel.id, mode: "ivr"}) |> Repo.insert

    respondent = insert(:respondent, survey: survey, respondent_group: group)

    {:ok, _} = Broker.start_link
    Broker.handle_info(:poll, nil)

    respondent = Repo.get(Respondent, respondent.id)
    reply = Broker.sync_step(respondent, Flow.Message.reply("Yes"), "sms")
    assert {:reply, ReplyHelper.simple("Do you exercise", "Do you exercise? Reply 1 for YES, 2 for NO")} = reply
  end

  def create_running_survey_with_channel_and_respondent(steps \\ @dummy_steps, mode \\ "sms") do
    test_channel = TestChannel.new(false, mode == "sms")

    channel_type = case mode do
      "mobileweb" -> "sms"
      _ -> mode
    end

    channel = insert(:channel, settings: test_channel |> TestChannel.settings, type: channel_type)
    quiz = insert(:questionnaire, steps: steps, quota_completed_steps: nil)
    survey = insert(:survey, Map.merge(@always_schedule, %{state: "running", questionnaires: [quiz], mode: [[mode]]}))
    group = insert(:respondent_group, survey: survey, respondents_count: 1) |> Repo.preload(:channels)

    RespondentGroupChannel.changeset(%RespondentGroupChannel{}, %{respondent_group_id: group.id, channel_id: channel.id, mode: mode}) |> Repo.insert

    respondent = insert(:respondent, survey: survey, respondent_group: group)
    phone_number = respondent.sanitized_phone_number

    [survey, group, test_channel, respondent, phone_number]
  end

  def create_several_respondents(survey, group, n) when n <= 1 do
    [insert(:respondent, survey: survey, respondent_group: group)]
  end

  def create_several_respondents(survey, group, n) do
    [create_several_respondents(survey, group, n - 1) | insert(:respondent, survey: survey, respondent_group: group)]
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

  defp tomorrow_schedule_day_of_week() do
    {erl_date, _} = Timex.now |> Timex.to_erl
    case :calendar.day_of_the_week(erl_date) do
      1 -> %Ask.DayOfWeek{tue: true}
      2 -> %Ask.DayOfWeek{wed: true}
      3 -> %Ask.DayOfWeek{thu: true}
      4 -> %Ask.DayOfWeek{fri: true}
      5 -> %Ask.DayOfWeek{sat: true}
      6 -> %Ask.DayOfWeek{sun: true}
      7 -> %Ask.DayOfWeek{mon: true}
    end
  end

  defp mark_n_active_respondents_as(new_state, n) do
    Repo.all(from r in Respondent, where: r.state == "active", limit: ^n)
    |> Enum.map(fn respondent ->
      Repo.update(respondent |> change |> Respondent.changeset(%{state: new_state}))
    end)
  end
end
