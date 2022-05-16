defmodule AskWeb.SurveySimulationControllerTest do
  use AskWeb.ConnCase
  use Ask.TestHelpers
  use Ask.DummySteps
  use Ask.MockTime

  alias Ask.Respondent
  alias Ask.Runtime.{Session, ChannelStatusServer}

  setup %{conn: conn} do
    user = insert(:user)

    conn =
      conn
      |> put_private(:test_user, user)
      |> put_req_header("accept", "application/json")

    {:ok, conn: conn, user: user}
  end

  describe "simulate" do
    defp create_channel(mode) do
      channel_type =
        case mode do
          "mobileweb" -> "sms"
          _ -> mode
        end

      test_channel = Ask.TestChannel.new(false, mode == "sms")

      channel =
        insert(:channel, settings: test_channel |> Ask.TestChannel.settings(), type: channel_type)

      {test_channel, channel}
    end

    defp start_questionnaire_simulation(conn, user, mode) do
      {_, channel} = create_channel(mode)
      project = create_project_for_user(user)

      questionnaire =
        insert(:questionnaire, project: project, steps: @dummy_steps, quota_completed_steps: nil)

      conn =
        post(conn, project_survey_simulation_path(conn, :simulate, project), %{
          questionnaire_id: to_string(questionnaire.id),
          phone_number: "0123456789",
          mode: mode,
          channel_id: to_string(channel.id)
        })

      assert conn.status == 200

      survey = Survey |> Repo.get!(json_response(conn, 200)["data"]["id"])
      assert survey.mode == [[mode]]
      assert survey.state == :running
      assert survey.cutoff == 1
      assert survey.simulation == true

      assert survey |> assoc(:respondent_groups) |> Repo.aggregate(:count) == 1
      respondent_group = survey |> assoc(:respondent_groups) |> Repo.one()
      assert respondent_group.respondents_count == 1
      assert respondent_group.sample == ["0123456789"]

      assert survey |> assoc(:respondents) |> Repo.aggregate(:count) == 1
      respondent = survey |> assoc(:respondents) |> Repo.one()
      assert respondent.state == :pending
      assert respondent.phone_number == "0123456789"
    end

    test "starts a SMS simulation", %{conn: conn, user: user} do
      start_questionnaire_simulation(conn, user, "sms")
    end

    test "starts an IVR simulation", %{conn: conn, user: user} do
      start_questionnaire_simulation(conn, user, "ivr")
    end

    test "starts a Mobile Web simulation", %{conn: conn, user: user} do
      start_questionnaire_simulation(conn, user, "mobileweb")
    end
  end

  describe "stop" do
    setup %{conn: conn, user: user} do
      create_running_survey = fn simulation ->
        [survey | _tail] =
          create_running_survey_with_channel_and_respondent_with_options(
            user: user,
            simulation: simulation
          )

        %{survey: survey}
      end

      stop_simulation = fn survey ->
        post(conn, project_survey_survey_simulation_path(conn, :stop, survey.project, survey))
      end

      {:ok, create_running_survey: create_running_survey, stop_simulation: stop_simulation}
    end

    test "limits endpoint for survey simulations only", %{
      create_running_survey: create_running_survey,
      stop_simulation: stop_simulation
    } do
      simulation = false
      %{survey: survey} = create_running_survey.(simulation)

      assert_error_sent(:not_found, fn ->
        stop_simulation.(survey)
      end)
    end
  end

  describe "status" do
    setup %{conn: conn, user: user} do
      create_running_survey = fn simulation ->
        [survey | _tail] =
          create_running_survey_with_channel_and_respondent_with_options(
            user: user,
            simulation: simulation
          )

        %{survey: survey}
      end

      get_simulation_status = fn survey ->
        get(conn, project_survey_survey_simulation_path(conn, :status, survey.project, survey))
      end

      {:ok,
       create_running_survey: create_running_survey, get_simulation_status: get_simulation_status}
    end

    test "limits endpoint for survey simulations only", %{
      create_running_survey: create_running_survey,
      get_simulation_status: get_simulation_status
    } do
      simulation = false
      %{survey: survey} = create_running_survey.(simulation)

      assert_error_sent(:not_found, fn ->
        get_simulation_status.(survey)
      end)
    end
  end

  describe "initial state" do
    setup %{conn: conn, user: user} do
      create_running_survey = fn mode, simulation ->
        [survey, _group, _test_channel, respondent, _phone_number] =
          create_running_survey_with_channel_and_respondent_with_options(
            user: user,
            mode: mode,
            simulation: simulation
          )

        %{survey: survey, respondent_id: respondent.id}
      end

      get_simulation_initial_state = fn survey, mode ->
        get(
          conn,
          project_survey_survey_simulation_path(
            conn,
            :initial_state,
            survey.project,
            survey,
            mode
          )
        )
      end

      poll_survey = fn ->
        Broker.start_link()
        {:ok, _pid} = ChannelStatusServer.start_link()
        Process.register(self(), :mail_target)
        Broker.poll()
      end

      mobile_contact_messages = fn respondent_id ->
        Repo.get!(Respondent, respondent_id)
        |> Session.load_respondent_session(true)
        |> Session.mobile_contact_message()
      end

      {:ok,
       create_running_survey: create_running_survey,
       get_simulation_initial_state: get_simulation_initial_state,
       poll_survey: poll_survey,
       mobile_contact_messages: mobile_contact_messages}
    end

    test "limits endpoint for survey simulations only", %{
      create_running_survey: create_running_survey,
      get_simulation_initial_state: get_simulation_initial_state
    } do
      {mode, simulation} = {"sms", false}
      %{survey: survey} = create_running_survey.(mode, simulation)

      assert_error_sent(:not_found, fn ->
        get_simulation_initial_state.(survey, mode)
      end)
    end

    test "SMS return an empty map", %{
      create_running_survey: create_running_survey,
      get_simulation_initial_state: get_simulation_initial_state
    } do
      {mode, simulation} = {"sms", true}
      %{survey: survey} = create_running_survey.(mode, simulation)

      conn = get_simulation_initial_state.(survey, mode)

      assert json_response(conn, 200)["data"] == %{}
    end

    test "IVR return an empty map", %{
      create_running_survey: create_running_survey,
      get_simulation_initial_state: get_simulation_initial_state
    } do
      {mode, simulation} = {"ivr", true}
      %{survey: survey} = create_running_survey.(mode, simulation)

      conn = get_simulation_initial_state.(survey, mode)

      assert json_response(conn, 200)["data"] == %{}
    end

    test "Mobileweb fails when the respondent isn't ready", %{
      create_running_survey: create_running_survey,
      get_simulation_initial_state: get_simulation_initial_state
    } do
      {mode, simulation} = {"mobileweb", true}
      %{survey: survey} = create_running_survey.(mode, simulation)

      conn = get_simulation_initial_state.(survey, mode)

      %{status: status} = conn
      assert status == 404
    end

    test "Mobileweb answers when the respondent is ready", %{
      create_running_survey: create_running_survey,
      mobile_contact_messages: mobile_contact_messages,
      poll_survey: poll_survey,
      get_simulation_initial_state: get_simulation_initial_state
    } do
      {mode, simulation} = {"mobileweb", true}
      %{survey: survey, respondent_id: respondent_id} = create_running_survey.(mode, simulation)
      poll_survey.()

      conn = get_simulation_initial_state.(survey, mode)

      assert json_response(conn, 200)["data"]["mobile_contact_messages"] ==
               mobile_contact_messages.(respondent_id)
    end
  end
end
