defmodule Ask.QuestionnaireSimulationControllerTest do
  use Ask.ConnCase
  use Ask.DummySteps
  use Ask.TestHelpers
  import Ask.StepBuilder

  alias Ask.{Questionnaire, JsonSchema}

  setup %{conn: conn} do
    GenServer.start_link(JsonSchema, [], name: JsonSchema.server_ref)

    user = insert(:user)
    conn = conn
      |> put_private(:test_user, user)
      |> put_req_header("accept", "application/json")
    {:ok, conn: conn, user: user}
  end

  describe "start:" do
    setup [:start_simulator_store]

    test "renders json with the started SMS simulation", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      steps = @dummy_steps
      questionnaire = insert(:questionnaire, project: project)
      |> Questionnaire.changeset(%{steps: steps})
      |> Repo.update!
      |> Repo.preload(:project)
      conn = post conn, project_questionnaire_questionnaires_start_simulation_path(conn, :start, questionnaire.project, questionnaire), mode: "sms"
      first_step_id = hd(steps)["id"]

      assert %{
       "respondent_id" => _respondent_id,
       "submissions" => [],
       "messages_history" => [%{
         "type" => "ao",
         "body" => "Do you smoke? Reply 1 for YES, 2 for NO"
       },
       ],
       "current_step" => ^first_step_id,
       "disposition" => "contacted",
       "simulation_status" => "active",
       "questionnaire" => quiz
      } = json_response(conn, 200)
      assert questionnaire.steps == quiz["steps"]
    end

    test "renders json with the started IVR simulation", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      steps = @dummy_steps
      questionnaire = insert(:questionnaire, project: project)
      |> Questionnaire.changeset(%{steps: steps})
      |> Repo.update!
      |> Repo.preload(:project)
      conn = post conn, project_questionnaire_questionnaires_start_simulation_path(conn, :start, questionnaire.project, questionnaire), mode: "ivr"
      first_step_id = hd(steps)["id"]

      assert %{
        "respondent_id" => _respondent_id,
        "submissions" => [],
        "messages_history" => [
          %{"type" => "ao", "body" => "Do you smoke? Press 8 for YES, 9 for NO"}
        ],
        "prompts" => [
          %{"audio_source" => "tts", "text" => "Do you smoke? Press 8 for YES, 9 for NO"},
        ],
        "current_step" => ^first_step_id,
        "disposition" => "contacted",
        "simulation_status" => "active",
        "questionnaire" => quiz
      } = json_response(conn, 200)
      assert questionnaire.steps == quiz["steps"]
    end

    test "renders json with submissions if questionnaire starts with an explanation step", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      dummy_steps = @dummy_steps
      explanation_step = explanation_step(id: "1", title: "Explanation", prompt: prompt(sms: sms_prompt("Welcome to the survey")), skip_logic: nil)
      steps = [explanation_step] ++ dummy_steps
      questionnaire = insert(:questionnaire, project: project)
                      |> Questionnaire.changeset(%{steps: steps})
                      |> Repo.update!
                      |> Repo.preload(:project)
      conn = post conn, project_questionnaire_questionnaires_start_simulation_path(conn, :start, questionnaire.project, questionnaire), mode: "sms"
      first_dummy_step_id = hd(dummy_steps)["id"]

      assert %{
       "respondent_id" => _respondent_id,
       "submissions" => [%{
         "step_id" => "1"
       }],
       "messages_history" => [%{
         "type" => "ao",
         "body" => "Welcome to the survey"
       }, %{
         "type" => "ao",
         "body" => "Do you smoke? Reply 1 for YES, 2 for NO"
       },
       ],
       "current_step" => ^first_dummy_step_id,
       "disposition" => "contacted",
       "simulation_status" => "active",
       "questionnaire" => quiz
       } = json_response(conn, 200)
      assert questionnaire.steps == quiz["steps"]
    end

    test "doesn't start if questionnaire doesn't belong to project", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      steps = @dummy_steps
      questionnaire = insert(:questionnaire)
                      |> Questionnaire.changeset(%{steps: steps})
                      |> Repo.update!
      conn = post conn, project_questionnaire_questionnaires_start_simulation_path(conn, :start, project, questionnaire), mode: "sms"
      assert %{"error" => "Not found"} == json_response(conn, 404)
    end

    test "doesn't start if mode is not specified", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      steps = @dummy_steps
      questionnaire = insert(:questionnaire, project: project)
                      |> Questionnaire.changeset(%{steps: steps})
                      |> Repo.update!
                      |> Repo.preload(:project)
      conn = post conn, project_questionnaire_questionnaires_start_simulation_path(conn, :start, questionnaire.project, questionnaire)
      assert %{"error" => "Bad request"} == json_response(conn, 400)
    end

    test "doesn't start if mode is not supported", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      steps = @dummy_steps
      questionnaire = insert(:questionnaire, project: project)
                      |> Questionnaire.changeset(%{steps: steps})
                      |> Repo.update!
                      |> Repo.preload(:project)
      conn = post conn, project_questionnaire_questionnaires_start_simulation_path(conn, :start, questionnaire.project, questionnaire), mode: "unknown"
      assert %{"error" => "Bad request"} == json_response(conn, 400)
    end
  end

  describe "sync:" do
    setup [:start_simulator_store]

    test "renders json for started SMS simulation", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      steps = @dummy_steps
      questionnaire = insert(:questionnaire, project: project)
                      |> Questionnaire.changeset(%{steps: steps})
                      |> Repo.update!
                      |> Repo.preload(:project)

      conn_ = post conn, project_questionnaire_questionnaires_start_simulation_path(conn, :start, questionnaire.project, questionnaire), mode: "sms"
      respondent_id = json_response(conn_, 200)["respondent_id"]

      conn = post conn, project_questionnaire_questionnaires_sync_simulation_path(conn, :sync, questionnaire.project, questionnaire), respondent_id: respondent_id, response: "2", mode: "sms"
      first_step_id = hd(steps)["id"]
      second_step_id = (steps |> Enum.at(1))["id"]
      response = json_response(conn, 200)
      assert %{
       "respondent_id" => ^respondent_id,
       "submissions" => [%{
         "step_id" => ^first_step_id,
         "response" => "No"
       }],
       "messages_history" => [%{
         "type" => "ao",
         "body" => "Do you smoke? Reply 1 for YES, 2 for NO"
       }, %{
         "type" => "at",
         "body" => "2"
       }, %{
         "type" => "ao",
         "body" => "Do you exercise? Reply 1 for YES, 2 for NO"
       }
       ],
       "current_step" => ^second_step_id,
       "disposition" => "started",
       "simulation_status" => "active"
      } = response
      assert not (response |> Map.has_key?("questionnaire"))
    end

    test "renders json for started IVR simulation", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      steps = @dummy_steps
      questionnaire = insert(:questionnaire, project: project)
                      |> Questionnaire.changeset(%{steps: steps})
                      |> Repo.update!
                      |> Repo.preload(:project)

      conn_ = post conn, project_questionnaire_questionnaires_start_simulation_path(conn, :start, questionnaire.project, questionnaire), mode: "ivr"
      respondent_id = json_response(conn_, 200)["respondent_id"]

      conn = post conn, project_questionnaire_questionnaires_sync_simulation_path(conn, :sync, questionnaire.project, questionnaire), respondent_id: respondent_id, response: "8", mode: "ivr"
      first_step_id = hd(steps)["id"]
      second_step_id = (steps |> Enum.at(1))["id"]

      response = json_response(conn, 200)

      assert %{
        "respondent_id" => ^respondent_id,
        "submissions" => [
          %{ "step_id" => ^first_step_id, "response" => "Yes" },
        ],
        "messages_history" => [
          %{ "type" => "ao", "body" => "Do you smoke? Press 8 for YES, 9 for NO" },
          %{ "type" => "at", "body" => "8" },
          %{ "type" => "ao", "body" => "Do you exercise? Press 1 for YES, 2 for NO" },
        ],
        "prompts" => [
          %{"audio_source" => "tts", "text" => "Do you exercise? Press 1 for YES, 2 for NO"},
        ],
        "current_step" => ^second_step_id,
        "disposition" => "started",
        "simulation_status" => "active"
      } = response

      assert not (response |> Map.has_key?("questionnaire"))
    end

    test "renders json for expired simulation", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, project: project) |> Repo.preload(:project)
      respondent_id = Ecto.UUID.generate()

      conn = post conn, project_questionnaire_questionnaires_sync_simulation_path(conn, :sync, questionnaire.project, questionnaire), respondent_id: respondent_id, response: "2", mode: "sms"
      %{
        "respondent_id" => ^respondent_id,
        "simulation_status" => "expired"
      } = json_response(conn, 200)
    end

    test "renders ended SMS simulation if last response", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      step = hd(@dummy_steps)
      questionnaire = insert(:questionnaire, project: project)
                      |> Questionnaire.changeset(%{steps: [step]})
                      |> Repo.update!
                      |> Repo.preload(:project)

      conn_ = post conn, project_questionnaire_questionnaires_start_simulation_path(conn, :start, questionnaire.project, questionnaire), mode: "sms"
      respondent_id = json_response(conn_, 200)["respondent_id"]

      conn = post conn, project_questionnaire_questionnaires_sync_simulation_path(conn, :sync, questionnaire.project, questionnaire), respondent_id: respondent_id, response: "2", mode: "sms"
      first_step_id = step["id"]

      assert %{
       "respondent_id" => ^respondent_id,
       "submissions" => [%{
         "step_id" => ^first_step_id,
         "response" => "No"
       }],
       "messages_history" => [%{
         "type" => "ao",
         "body" => "Do you smoke? Reply 1 for YES, 2 for NO"
       }, %{
         "type" => "at",
         "body" => "2"
       }, %{
         "type" => "ao",
         "body" => "Thanks for completing this survey"
       }
       ],
       "disposition" => "completed",
       "simulation_status" => "ended"
     } = json_response(conn, 200)
    end

    test "renders ended IVR simulation if last response", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      step = hd(@dummy_steps)
      questionnaire = insert(:questionnaire, project: project)
                      |> Questionnaire.changeset(%{steps: [step]})
                      |> Repo.update!
                      |> Repo.preload(:project)

      conn_ = post conn, project_questionnaire_questionnaires_start_simulation_path(conn, :start, questionnaire.project, questionnaire), mode: "ivr"
      respondent_id = json_response(conn_, 200)["respondent_id"]

      conn = post conn, project_questionnaire_questionnaires_sync_simulation_path(conn, :sync, questionnaire.project, questionnaire), respondent_id: respondent_id, response: "9", mode: "ivr"
      first_step_id = step["id"]

      assert %{
        "respondent_id" => ^respondent_id,
        "submissions" => [
          %{ "step_id" => ^first_step_id, "response" => "No" },
        ],
        "messages_history" => [
          %{ "type" => "ao", "body" => "Do you smoke? Press 8 for YES, 9 for NO" },
          %{ "type" => "at", "body" => "9" },
          %{ "type" => "ao", "body" => "Thanks for completing this survey (ivr)" },
        ],
        "prompts" => [
          %{ "audio_source" => "tts", "text" => "Thanks for completing this survey (ivr)" },
        ],
        "disposition" => "completed",
        "simulation_status" => "ended"
      } = json_response(conn, 200)
    end
  end

  defp start_simulator_store(_context) do
    Ask.Runtime.QuestionnaireSimulatorStore.start_link()
    :ok
  end
end
