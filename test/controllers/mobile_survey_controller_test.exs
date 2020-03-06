defmodule Ask.MobileSurveyControllerTest do
  use Ask.ConnCase
  use Ask.TestHelpers
  use Ask.DummySteps
  use Timex
  alias Ask.Runtime.{Broker, ReplyHelper, ChannelStatusServer}
  alias Ask.{Repo, Survey, Respondent, TestChannel, RespondentGroupChannel}
  require Ask.Runtime.ReplyHelper

  setup %{conn: conn} do
    conn = conn
      |> put_req_header("accept", "application/json")
    ChannelStatusServer.start_link

    {:ok, conn: conn}
  end

  describe "index" do
    setup %{conn: conn} do
      test_channel = TestChannel.new(false, true)

      channel = insert(:channel, settings: test_channel |> TestChannel.settings, type: "sms")
      quiz = insert(:questionnaire, steps: @mobileweb_dummy_steps, settings: %{"error_message" => %{"en" => %{"mobileweb" => "Invalid value"}}, "title" => %{"en" => "Survey"}, "mobile_web_intro_message" => "My HTML escaped & intro message", "mobile_web_color_style" => %{"secondary_color" => "#ae1", "primary_color" => "#e21"}})
      survey = insert(:survey, %{schedule: Ask.Schedule.always(), state: "running", questionnaires: [quiz], mode: [["mobileweb"]]})
      group = insert(:respondent_group, survey: survey, respondents_count: 1) |> Repo.preload(:channels)

      RespondentGroupChannel.changeset(%RespondentGroupChannel{}, %{respondent_group_id: group.id, channel_id: channel.id, mode: "mobileweb"}) |> Repo.insert

      respondent = insert(:respondent, survey: survey, respondent_group: group)

      Broker.start_link
      Ask.Config.start_link
      Broker.poll

      {:ok, conn: conn, respondent: respondent}
    end

    test "includes config in root", %{conn: conn, respondent: respondent} do
      conn = get conn, mobile_survey_path(conn, :index, respondent.id, %{token: Respondent.token(respondent.id)})

      response = response(conn, 200)

      assert String.contains?(response, "<div id=\"root\" role=\"main\" data-config=\"{&quot;introMessage&quot;:&quot;My HTML escaped &amp; intro message&quot;,&quot;colorStyle&quot;:{&quot;secondary_color&quot;:&quot;#ae1&quot;,&quot;primary_color&quot;:&quot;#e21&quot;}}\"></div>\n")
    end
  end

  test "respondent flow via mobileweb", %{conn: conn} do
    test_channel = TestChannel.new(false, true)

    channel = insert(:channel, settings: test_channel |> TestChannel.settings, type: "sms")
    quiz = insert(:questionnaire, steps: @mobileweb_dummy_steps, settings: %{"error_message" => %{"en" => %{"mobileweb" => "Invalid value"}}, "title" => %{"en" => "Survey"}})
    survey = insert(:survey, %{schedule: Ask.Schedule.always(), state: "running", questionnaires: [quiz], mode: [["mobileweb"]]})
    group = insert(:respondent_group, survey: survey, respondents_count: 1) |> Repo.preload(:channels)

    RespondentGroupChannel.changeset(%RespondentGroupChannel{}, %{respondent_group_id: group.id, channel_id: channel.id, mode: "mobileweb"}) |> Repo.insert

    respondent = insert(:respondent, survey: survey, respondent_group: group)
    phone_number = respondent.sanitized_phone_number
    token = Respondent.token(respondent.id)
    cookie_name = Respondent.mobile_web_cookie_name(respondent.id)

    {:ok, broker} = Broker.start_link
    Broker.poll

    assert_receive [:ask, ^test_channel, %Respondent{sanitized_phone_number: ^phone_number}, _, ReplyHelper.simple("Contact", message)]
    assert message == "Please enter #{mobile_survey_url(Ask.Endpoint, :index, respondent.id, token: Respondent.token(respondent.id))}"

    survey = Repo.get(Survey, survey.id)
    assert survey.state == "running"

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "active"
    # mobile_survey_send_reply_path

    # Check that get_step without token gives error
    assert_error_sent :bad_request, fn ->
      get conn, mobile_survey_path(conn, :get_step, respondent.id)
    end

    original_conn = conn

    conn = get conn, mobile_survey_path(conn, :get_step, respondent.id, %{token: token})
    json = json_response(conn, 200)

    # A cookie should have been generated
    %{value: mobile_web_code} = conn.resp_cookies[cookie_name]
    assert mobile_web_code

    # Check again without a cookie
    assert_error_sent :forbidden, fn ->
      get original_conn, mobile_survey_path(conn, :get_step, respondent.id, %{token: token})
    end

    assert %{
      "choices" => [],
      "prompts" => ["Welcome to the survey!"],
      "title" => "Let there be rock",
      "type" => "explanation"
    } = json["step"]
    assert json["progress"] == 20.0

    conn = get conn, mobile_survey_path(conn, :get_step, respondent.id, %{token: token})
    json = json_response(conn, 200)
    assert %{
      "choices" => [],
      "prompts" => ["Welcome to the survey!"],
      "title" => "Let there be rock",
      "type" => "explanation"
    } = json["step"]
    assert json["progress"] == 20.0

    # Check that send_reply without token gives error
    assert_error_sent :bad_request, fn ->
      post conn, mobile_survey_path(conn, :send_reply, respondent.id, %{value: "", step_id: "s1"})
    end

    # Check without a cookie
    assert_error_sent :forbidden, fn ->
      post original_conn, mobile_survey_path(conn, :send_reply, respondent.id, %{token: token, value: "", step_id: "s1"})
    end

    conn = post conn, mobile_survey_path(conn, :send_reply, respondent.id, %{token: token, value: "", step_id: "s1"})
    json = json_response(conn, 200)
    assert %{
      "choices" => [["Yes"], ["No"]],
      "prompts" => ["Do you smoke?"],
      "title" => "Do you smoke?",
      "type" => "multiple-choice"
    } = json["step"]
    assert json["progress"] == 40.0

    conn = get conn, mobile_survey_path(conn, :get_step, respondent.id, %{token: token})
    json = json_response(conn, 200)
    assert %{
      "choices" => [["Yes"], ["No"]],
      "prompts" => ["Do you smoke?"],
      "title" => "Do you smoke?",
      "type" => "multiple-choice"
    } = json["step"]
    assert json["progress"] == 40.0

    conn = get conn, mobile_survey_path(conn, :get_step, respondent.id, %{token: token})
    json = json_response(conn, 200)
    assert %{
      "choices" => [["Yes"], ["No"]],
      "prompts" => ["Do you smoke?"],
      "title" => "Do you smoke?",
      "type" => "multiple-choice"
    } = json["step"]
    assert json["progress"] == 40.0

    # Check before flag step
    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.disposition == "started"

    conn = post conn, mobile_survey_path(conn, :send_reply, respondent.id, %{token: token, value: "Yes", step_id: "s2"})
    json = json_response(conn, 200)
    assert %{
      "choices" => [["Yes"], ["No"]],
      "prompts" => ["Do you exercise?"],
      "title" => "Do you exercise",
      "type" => "multiple-choice"
    } = json["step"]
    assert json["progress"] == 60.0

    # Check after flag step
    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.disposition == "interim partial"

    conn = post conn, mobile_survey_path(conn, :send_reply, respondent.id, %{token: token, value: "Yes", step_id: "s4"})
    json = json_response(conn, 200)
    assert %{
      "prompts" => ["Which is the second perfect number??"],
      "title" => "Which is the second perfect number?",
      "type" => "numeric",
      "refusal" => "skip me"
    } = json["step"]
    assert json["progress"] == 80.0
    assert json["error_message"] == "Invalid value"

    # Reply a previous step (should reply with the current step)
    conn = post conn, mobile_survey_path(conn, :send_reply, respondent.id, %{token: token, value: "Yes", step_id: "s2"})
    json = json_response(conn, 200)
    assert %{
      "prompts" => ["Which is the second perfect number??"],
      "title" => "Which is the second perfect number?",
      "type" => "numeric"
    } = json["step"]
    assert json["progress"] == 80.0
    assert json["error_message"] == "Invalid value"

    conn = post conn, mobile_survey_path(conn, :send_reply, respondent.id, %{token: token, value: "99", step_id: "s5"})
    json = json_response(conn, 200)
    assert %{
      "prompts" => ["What's the number of this question??"],
      "title" => "What's the number of this question?",
      "type" => "numeric"
    } = json["step"]
    assert json["progress"] == 100.0

    conn = post conn, mobile_survey_path(conn, :send_reply, respondent.id, %{token: token, value: "11", step_id: "s6"})
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
    survey = insert(:survey, %{schedule: Ask.Schedule.always(), state: "running", questionnaires: [quiz], mode: [["mobileweb"]]})
    group = insert(:respondent_group, survey: survey, respondents_count: 1) |> Repo.preload(:channels)

    RespondentGroupChannel.changeset(%RespondentGroupChannel{}, %{respondent_group_id: group.id, channel_id: channel.id, mode: "mobileweb"}) |> Repo.insert

    respondent = insert(:respondent, survey: survey, respondent_group: group)
    phone_number = respondent.sanitized_phone_number

    {:ok, broker} = Broker.start_link
    {:ok, config} = Ask.Config.start_link
    Broker.poll

    assert_receive [:ask, ^test_channel, %Respondent{sanitized_phone_number: ^phone_number}, _, ReplyHelper.simple("Contact", message)]
    assert message == "Please enter #{mobile_survey_url(Ask.Endpoint, :index, respondent.id, token: Respondent.token(respondent.id))}"

    conn = get conn, mobile_survey_path(conn, :index, respondent.id, %{token: Respondent.token(respondent.id)})
    assert response(conn, 200)

    conn = get conn, mobile_survey_path(conn, :index, respondent.id, %{token: "some invalid token"})
    assert conn.status == 403

    :ok = broker |> GenServer.stop
    :ok = config |> GenServer.stop
  end

  test "respondent flow via mobileweb when respondent state is not active nor stalled nor pending", %{conn: conn} do
    test_channel = TestChannel.new(false, true)

    channel = insert(:channel, settings: test_channel |> TestChannel.settings, type: "sms")
    quiz = insert(:questionnaire, steps: @mobileweb_dummy_steps, settings: %{"survey_already_taken_message" => %{"en" => "Already took this"}})
    survey = insert(:survey, %{schedule: Ask.Schedule.always(), state: "running", questionnaires: [quiz], mode: [["mobileweb"]]})
    group = insert(:respondent_group, survey: survey, respondents_count: 1) |> Repo.preload(:channels)

    RespondentGroupChannel.changeset(%RespondentGroupChannel{}, %{respondent_group_id: group.id, channel_id: channel.id, mode: "mobileweb"}) |> Repo.insert

    respondent = insert(:respondent, survey: survey, respondent_group: group)
    token = Respondent.token(respondent.id)

    {:ok, _} = Broker.start_link
    Broker.poll

    respondent = Repo.get(Respondent, respondent.id)
    respondent |> Respondent.changeset(%{"state" => "completed"}) |> Repo.update!

    conn = get conn, mobile_survey_path(conn, :get_step, respondent.id, %{token: token})
    assert %{
      "prompts" => ["Already took this"],
      "title" => "Already took this",
      "type" => "end"
    } = json_response(conn, 200)["step"]
  end

  test "respondent flow via mobileweb when survey is over", %{conn: conn} do
    test_channel = TestChannel.new(false, true)

    channel = insert(:channel, settings: test_channel |> TestChannel.settings, type: "sms")
    quiz = insert(:questionnaire, steps: @mobileweb_dummy_steps, settings: %{"mobile_web_survey_is_over_message" => "Bye"})
    survey = insert(:survey, %{schedule: Ask.Schedule.always(), state: "running", questionnaires: [quiz], mode: [["mobileweb"]]})
    group = insert(:respondent_group, survey: survey, respondents_count: 1) |> Repo.preload(:channels)

    RespondentGroupChannel.changeset(%RespondentGroupChannel{}, %{respondent_group_id: group.id, channel_id: channel.id, mode: "mobileweb"}) |> Repo.insert

    respondent = insert(:respondent, survey: survey, respondent_group: group)
    token = Respondent.token(respondent.id)

    {:ok, _} = Broker.start_link
    Broker.poll

    survey |> Survey.changeset(%{"state" => "terminated", "exit_code" => 0, "exit_message" => "Successfully completed"}) |> Repo.update!

    conn = get conn, mobile_survey_path(conn, :get_step, respondent.id, %{token: token})
    assert %{
      "prompts" => ["Bye"],
      "title" => "Bye",
      "type" => "end"
    } = json_response(conn, 200)["step"]
  end

  test "respondent flow via mobileweb with refusal + end", %{conn: conn} do
    test_channel = TestChannel.new(false, true)

    channel = insert(:channel, settings: test_channel |> TestChannel.settings, type: "sms")
    quiz = insert(:questionnaire, steps: @mobileweb_refusal_dummy_steps, settings: %{"error_message" => %{"en" => %{"mobileweb" => "Invalid value"}}})
    survey = insert(:survey, %{schedule: Ask.Schedule.always(), state: "running", questionnaires: [quiz], mode: [["mobileweb"]]})
    group = insert(:respondent_group, survey: survey, respondents_count: 1) |> Repo.preload(:channels)

    RespondentGroupChannel.changeset(%RespondentGroupChannel{}, %{respondent_group_id: group.id, channel_id: channel.id, mode: "mobileweb"}) |> Repo.insert

    respondent = insert(:respondent, survey: survey, respondent_group: group)
    phone_number = respondent.sanitized_phone_number
    token = Respondent.token(respondent.id)

    {:ok, broker} = Broker.start_link
    Broker.poll

    assert_receive [:ask, ^test_channel, %Respondent{sanitized_phone_number: ^phone_number}, _, ReplyHelper.simple("Contact", message)]
    assert message == "Please enter #{mobile_survey_url(Ask.Endpoint, :index, respondent.id, token: Respondent.token(respondent.id))}"

    survey = Repo.get(Survey, survey.id)
    assert survey.state == "running"

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.state == "active"
    # mobile_survey_send_reply_path

    conn = get conn, mobile_survey_path(conn, :get_step, respondent.id, %{token: token})
    json = json_response(conn, 200)

    assert %{
      "choices" => [],
      "prompts" => ["Welcome to the survey!"],
      "title" => "Let there be rock",
      "type" => "explanation"
    } = json["step"]
    assert json["progress"] == 100.0

    post conn, mobile_survey_path(conn, :send_reply, respondent.id, %{token: token, value: "", step_id: "s1"})

    respondent = Repo.get(Respondent, respondent.id)
    assert respondent.disposition == "refused"

    :ok = broker |> GenServer.stop
  end

  test "gets 404 when respondent is not found after survey deletion", %{conn: conn} do
    test_channel = TestChannel.new(false, true)

    channel = insert(:channel, settings: test_channel |> TestChannel.settings, type: "sms")
    quiz = insert(:questionnaire, steps: @mobileweb_dummy_steps)
    survey = insert(:survey, %{schedule: Ask.Schedule.always(), state: "running", questionnaires: [quiz], mode: [["mobileweb"]]})
    group = insert(:respondent_group, survey: survey, respondents_count: 1) |> Repo.preload(:channels)

    RespondentGroupChannel.changeset(%RespondentGroupChannel{}, %{respondent_group_id: group.id, channel_id: channel.id, mode: "mobileweb"}) |> Repo.insert

    respondent = insert(:respondent, survey: survey, respondent_group: group)

    Broker.start_link
    Ask.Config.start_link
    Broker.poll

    Survey |> Repo.get(survey.id) |> Repo.delete

    conn = get conn, mobile_survey_path(conn, :index, respondent.id, %{token: Respondent.token(respondent.id)})
    assert conn.status == 404
  end
end
