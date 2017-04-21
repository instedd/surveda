defmodule Ask.MobileSurveyControllerTest do
  use Ask.ConnCase
  use Ask.TestHelpers
  use Ask.DummySteps
  use Timex
  alias Ask.Runtime.{Broker, ReplyHelper}
  alias Ask.{Repo, Survey, Respondent, TestChannel, RespondentGroupChannel}
  require Ask.Runtime.ReplyHelper

  @everyday_schedule %Ask.DayOfWeek{mon: true, tue: true, wed: true, thu: true, fri: true, sat: true, sun: true}
  @always_schedule %{schedule_day_of_week: @everyday_schedule,
                     schedule_start_time: elem(Ecto.Time.cast("00:00:00"), 1),
                     schedule_end_time: elem(Ecto.Time.cast("23:59:59"), 1)}

  setup %{conn: conn} do
    conn = conn
      |> put_req_header("accept", "application/json")

    {:ok, conn: conn}
  end

  test "respondent flow via mobileweb", %{conn: conn} do
    test_channel = TestChannel.new(false, true)

    channel = insert(:channel, settings: test_channel |> TestChannel.settings, type: "sms")
    quiz = insert(:questionnaire, steps: @mobileweb_dummy_steps)
    survey = insert(:survey, Map.merge(@always_schedule, %{state: "running", questionnaires: [quiz], mode: [["mobileweb"]]}))
    group = insert(:respondent_group, survey: survey, respondents_count: 1) |> Repo.preload(:channels)

    RespondentGroupChannel.changeset(%RespondentGroupChannel{}, %{respondent_group_id: group.id, channel_id: channel.id, mode: "mobileweb"}) |> Repo.insert

    respondent = insert(:respondent, survey: survey, respondent_group: group)
    phone_number = respondent.sanitized_phone_number

    {:ok, broker} = Broker.start_link
    Broker.poll

    assert_receive [:ask, ^test_channel, %Respondent{sanitized_phone_number: ^phone_number}, _, ReplyHelper.simple("Contact", message)]
    assert message == "Please enter http://app.ask.dev/mobile_survey/#{respondent.id}?token=#{Respondent.token(respondent.id)}"

    survey = Repo.get(Survey, survey.id)
    assert survey.state == "running"

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "active"
    # mobile_survey_send_reply_path

    conn = get conn, mobile_survey_path(conn, :get_step, respondent.id)
    json = json_response(conn, 200)

    assert %{
      "choices" => [],
      "prompts" => ["Welcome to the survey!"],
      "title" => "Let there be rock",
      "type" => "explanation"
    } = json["step"]
    assert json["progress"] == 0.0

    conn = get conn, mobile_survey_path(conn, :get_step, respondent.id)
    json = json_response(conn, 200)
    assert %{
      "choices" => [],
      "prompts" => ["Welcome to the survey!"],
      "title" => "Let there be rock",
      "type" => "explanation"
    } = json["step"]
    assert json["progress"] == 0.0

    conn = post conn, mobile_survey_path(conn, :send_reply, respondent.id, %{value: ""})
    json = json_response(conn, 200)
    assert %{
      "choices" => [["Yes"], ["No"]],
      "prompts" => ["Do you smoke? Reply 1 for YES, 2 for NO"],
      "title" => "Do you smoke?",
      "type" => "multiple-choice"
    } = json["step"]
    assert json["progress"] == 20.0

    conn = get conn, mobile_survey_path(conn, :get_step, respondent.id)
    json = json_response(conn, 200)
    assert %{
      "choices" => [["Yes"], ["No"]],
      "prompts" => ["Do you smoke? Reply 1 for YES, 2 for NO"],
      "title" => "Do you smoke?",
      "type" => "multiple-choice"
    } = json["step"]
    assert json["progress"] == 20.0

    conn = get conn, mobile_survey_path(conn, :get_step, respondent.id)
    json = json_response(conn, 200)
    assert %{
      "choices" => [["Yes"], ["No"]],
      "prompts" => ["Do you smoke? Reply 1 for YES, 2 for NO"],
      "title" => "Do you smoke?",
      "type" => "multiple-choice"
    } = json["step"]
    assert json["progress"] == 20.0

    # Check before flag step
    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.disposition == nil

    conn = post conn, mobile_survey_path(conn, :send_reply, respondent.id, %{value: "Yes"})
    json = json_response(conn, 200)
    assert %{
      "choices" => [["Yes"], ["No"]],
      "prompts" => ["Do you exercise? Reply 1 for YES, 2 for NO"],
      "title" => "Do you exercise",
      "type" => "multiple-choice"
    } = json["step"]
    assert json["progress"] == 40.0

    # Check after flag step
    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.disposition == "partial"

    conn = post conn, mobile_survey_path(conn, :send_reply, respondent.id, %{value: "Yes"})
    json = json_response(conn, 200)
    assert %{
      "prompts" => ["Which is the second perfect number??"],
      "title" => "Which is the second perfect number?",
      "type" => "numeric"
    } = json["step"]
    assert json["progress"] == 60.0

    conn = post conn, mobile_survey_path(conn, :send_reply, respondent.id, %{value: "99"})
    json = json_response(conn, 200)
    assert %{
      "prompts" => ["What's the number of this question??"],
      "title" => "What's the number of this question?",
      "type" => "numeric"
    } = json["step"]
    assert json["progress"] == 80.0

    conn = post conn, mobile_survey_path(conn, :send_reply, respondent.id, %{value: "11"})
    json = json_response(conn, 200)
    assert %{
      "prompts" => ["The survey has ended"],
      "title" => "The survey has ended",
      "type" => "end"
    } = json["step"]
    assert json["progress"] == 100.0

    now = Timex.now
    interval = Interval.new(from: Timex.shift(now, seconds: -5), until: Timex.shift(now, seconds: 5), step: [seconds: 1])

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "completed"
    assert respondent.session == nil
    assert respondent.completed_at in interval

    :ok = broker |> GenServer.stop
  end

  test "using an invalid token", %{conn: conn} do
    test_channel = TestChannel.new(false, true)

    channel = insert(:channel, settings: test_channel |> TestChannel.settings, type: "sms")
    quiz = insert(:questionnaire, steps: @mobileweb_dummy_steps)
    survey = insert(:survey, Map.merge(@always_schedule, %{state: "running", questionnaires: [quiz], mode: [["mobileweb"]]}))
    group = insert(:respondent_group, survey: survey, respondents_count: 1) |> Repo.preload(:channels)

    RespondentGroupChannel.changeset(%RespondentGroupChannel{}, %{respondent_group_id: group.id, channel_id: channel.id, mode: "mobileweb"}) |> Repo.insert

    respondent = insert(:respondent, survey: survey, respondent_group: group)
    phone_number = respondent.sanitized_phone_number

    {:ok, broker} = Broker.start_link
    {:ok, config} = Ask.Config.start_link
    Broker.poll

    assert_receive [:ask, ^test_channel, %Respondent{sanitized_phone_number: ^phone_number}, _, ReplyHelper.simple("Contact", message)]
    assert message == "Please enter http://app.ask.dev/mobile_survey/#{respondent.id}?token=#{Respondent.token(respondent.id)}"

    conn = get conn, mobile_survey_path(conn, :index, respondent.id, %{token: Respondent.token(respondent.id)})
    assert response(conn, 200)

    assert_error_sent :forbidden, fn ->
      get conn, mobile_survey_path(conn, :index, respondent.id, %{token: "some invalid token"})
    end

    :ok = broker |> GenServer.stop
    :ok = config |> GenServer.stop
  end

  test "respondent flow via mobileweb when respondent state is not active nor stalled nor pending", %{conn: conn} do
    test_channel = TestChannel.new(false, true)

    channel = insert(:channel, settings: test_channel |> TestChannel.settings, type: "sms")
    quiz = insert(:questionnaire, steps: @mobileweb_dummy_steps)
    survey = insert(:survey, Map.merge(@always_schedule, %{state: "running", questionnaires: [quiz], mode: [["mobileweb"]]}))
    group = insert(:respondent_group, survey: survey, respondents_count: 1) |> Repo.preload(:channels)

    RespondentGroupChannel.changeset(%RespondentGroupChannel{}, %{respondent_group_id: group.id, channel_id: channel.id, mode: "mobileweb"}) |> Repo.insert

    respondent = insert(:respondent, survey: survey, respondent_group: group)

    {:ok, _} = Broker.start_link
    Broker.poll

    respondent = Repo.get(Respondent, respondent.id)
    respondent |> Respondent.changeset(%{"state" => "finised"}) |> Repo.update!

    conn = get conn, mobile_survey_path(conn, :get_step, respondent.id)
    assert %{
      "prompts" => ["The survey has ended"],
      "title" => "The survey has ended",
      "type" => "end"
    } = json_response(conn, 200)["step"]
  end
end
