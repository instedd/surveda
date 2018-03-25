defmodule Ask.QuestionnaireControllerTest do
  use Ask.ConnCase
  use Ask.DummySteps
  use Ask.TestHelpers
  import Ask.StepBuilder

  alias Ask.{Project, Questionnaire, Translation, JsonSchema, ActivityLog}
  @valid_attrs %{name: "some content", modes: ["sms", "ivr"], steps: [], settings: %{}}
  @invalid_attrs %{steps: [], settings: %{}}

  setup %{conn: conn} do
    GenServer.start_link(JsonSchema, [], name: JsonSchema.server_ref)

    user = insert(:user)
    conn = conn
      |> put_private(:test_user, user)
      |> put_req_header("accept", "application/json")
    {:ok, conn: conn, user: user}
  end

  describe "login" do
    test "denies access without login token" do
      conn = build_conn()
      conn = get conn, project_questionnaire_path(conn, :index, -1)
      assert json_response(conn, :unauthorized)["error"] == "Unauthorized"
    end

    test "user is deleted from session if the user does not exist" do
      user = build(:user, id: -1)
      conn = build_conn()
      |> put_private(:test_user, user)
      |> put_req_header("accept", "application/json")
      conn = get conn, project_questionnaire_path(conn, :index, user)
      assert json_response(conn, :unauthorized)["error"] == "Unauthorized"
    end
  end

  describe "index:" do
    test "returns 404 when the project does not exist", %{conn: conn} do
      assert_error_sent 404, fn ->
        get conn, project_questionnaire_path(conn, :index, -1)
      end
    end

    test "returns code 200 and empty list if there are no entries", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      conn = get conn, project_questionnaire_path(conn, :index, project.id)
      assert json_response(conn, 200)["data"] == []
    end

    test "forbid index access if the project does not belong to the current user", %{conn: conn} do
      questionnaire = insert(:questionnaire)
      assert_error_sent :forbidden, fn ->
        get conn, project_questionnaire_path(conn, :index, questionnaire.project)
      end
    end

    test "doesn't show snapshots", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, project: project)
      insert(:questionnaire, project: project, snapshot_of: questionnaire.id)

      conn = get conn, project_questionnaire_path(conn, :index, project.id)
      data = json_response(conn, 200)["data"]
      assert length(data) == 1
      assert hd(data)["id"] == questionnaire.id
    end

    test "doesn't show deleted questionnaires", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      insert(:questionnaire, project: project, deleted: true)
      conn = get conn, project_questionnaire_path(conn, :index, project.id)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "show:" do
    test "renders chosen resource", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, project: project)
      questionnaire = Questionnaire |> Repo.get(questionnaire.id) |> Repo.preload(:project)
      conn = get conn, project_questionnaire_path(conn, :show, questionnaire.project, questionnaire)
      assert json_response(conn, 200)["data"] == %{"id" => questionnaire.id,
        "name" => questionnaire.name,
        "project_id" => questionnaire.project_id,
        "modes" => ["sms", "ivr"],
        "steps" => [],
        "quota_completed_steps" => [%{"id" => "quota-completed-step", "prompt" => %{"en" => %{"ivr" => %{"audio_source" => "tts", "text" => "Quota completed (ivr)"}, "sms" => "Quota completed"}}, "skip_logic" => nil, "title" => "Completed", "type" => "explanation"}],
        "default_language" => "en",
        "languages" => [],
        "updated_at" => NaiveDateTime.to_iso8601(questionnaire.updated_at),
        "valid" => true,
        "settings" => %{
          "error_message" => %{
            "en" => %{
              "sms" => "You have entered an invalid answer",
              "ivr" => %{
                "audio_source" => "tts",
                "text" => "You have entered an invalid answer (ivr)"
              }
            }
          },
          "mobile_web_sms_message" => "Please enter",
          "mobile_web_survey_is_over_message" => "Survey is over",
          "thank_you_message" => %{
            "en" => %{
              "sms" => "Thanks for completing this survey",
              "ivr" => %{
                "audio_source" => "tts",
                "text" => "Thanks for completing this survey (ivr)"
              },
              "mobileweb" => "Thanks for completing this survey (mobileweb)"
            }
          },
        }
      }
    end

    test "renders page not found when id is nonexistent", %{conn: conn} do
      assert_error_sent 404, fn ->
        get conn, project_questionnaire_path(conn, :show, -1, -1)
      end
    end

    test "forbid access to questionnaire if the project does not belong to the current user", %{conn: conn} do
      questionnaire = insert(:questionnaire)
      assert_error_sent :forbidden, fn ->
        get conn, project_questionnaire_path(conn, :show, questionnaire.project, questionnaire)
      end
    end

    test "don't show deleted questionnaire", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, project: project, deleted: true)
      assert_error_sent 404, fn ->
        get conn, project_questionnaire_path(conn, :show, questionnaire.project, questionnaire)
      end
    end
  end

  describe "create:" do
    test "creates and renders resource when data is valid", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      conn = post conn, project_questionnaire_path(conn, :create, project.id), questionnaire: @valid_attrs
      assert json_response(conn, 201)["data"]["id"]
      assert Repo.get_by(Questionnaire, @valid_attrs)
    end

    test "creates and renders resource with a full questionnaire", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      quiz = %{
        name: "some content",
        modes: ["sms", "ivr"],
        steps: @dummy_steps,
        settings: %{
          "error_message" => %{
            "en" => %{
              "sms" => "You have entered an invalid answer",
              "ivr" => %{
                "audio_source" => "tts",
                "text" => "You have entered an invalid answer (ivr)"
              },
              "mobileweb" => "You have entered an invalid answer (mobileweb)"
            }
          },
          "mobile_web_sms_message" => "Please enter",
          "mobile_web_survey_is_over_message" => "Survey is over",
          "thank_you_message" => %{
            "en" => %{
              "sms" => "Thanks for completing this survey",
              "ivr" => %{
                "audio_source" => "tts",
                "text" => "Thanks for completing this survey (ivr)"
              },
              "mobileweb" => "Thanks for completing this survey (mobileweb)"
            }
          },
        }
      }
      conn = post conn, project_questionnaire_path(conn, :create, project.id), questionnaire: quiz
      assert json_response(conn, 201)["data"]["id"]
      assert Repo.get_by(Questionnaire, quiz)
    end

    test "creates with default languages and default_language", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      conn = post conn, project_questionnaire_path(conn, :create, project.id), questionnaire: @valid_attrs
      questionnaire = Questionnaire |> Ask.Repo.get(json_response(conn, 201)["data"]["id"])
      assert questionnaire.languages == ["en"]
      assert questionnaire.default_language == "en"
    end

    test "does not create resource and renders errors when data is invalid", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      conn = post conn, project_questionnaire_path(conn, :create, project.id), questionnaire: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end

    test "forbids creation of questionnaire for a project that belongs to another user", %{conn: conn} do
      project = insert(:project)
      assert_error_sent :forbidden, fn ->
        post conn, project_questionnaire_path(conn, :create, project.id), questionnaire: @valid_attrs
      end
    end

    test "forbids creation of questionnaire for a project reader", %{conn: conn, user: user} do
      project = create_project_for_user(user, level: "reader")
      assert_error_sent :forbidden, fn ->
        post conn, project_questionnaire_path(conn, :create, project.id), questionnaire: @valid_attrs
      end
    end

    test "forbids creation if project is archived", %{conn: conn, user: user} do
      project = create_project_for_user(user, archived: true)
      assert_error_sent :forbidden, fn ->
        post conn, project_questionnaire_path(conn, :create, project.id), questionnaire: @valid_attrs
      end
    end

    test "updates project updated_at when questionnaire is created", %{conn: conn, user: user}  do
      datetime = Ecto.DateTime.cast!("2000-01-01 00:00:00")
      project = insert(:project, updated_at: datetime)
      insert(:project_membership, user: user, project: project, level: "owner")
      post conn, project_questionnaire_path(conn, :create, project.id), questionnaire: @valid_attrs

      project = Project |> Repo.get(project.id)
      assert Ecto.DateTime.compare((project.updated_at |> NaiveDateTime.to_erl |> Ecto.DateTime.from_erl), datetime) == :gt
    end

    test "creates and recreates variables", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = %{name: "some content", modes: ["sms", "ivr"], steps: @dummy_steps, settings: %{}}

      original_conn = conn

      conn = post original_conn, project_questionnaire_path(conn, :create, project.id), questionnaire: questionnaire
      id = json_response(conn, 201)["data"]["id"]
      assert id

      vars = (Questionnaire
      |> Repo.get!(id)
      |> Repo.preload(:questionnaire_variables)).questionnaire_variables
      assert length(vars) == 4

      steps = [
        multiple_choice_step(
          id: "aaa",
          title: "Title",
          prompt: %{
          },
          store: "Swims",
          choices: []
        )
      ]
      questionnaire = Questionnaire |> Repo.get!(id)

      conn = put original_conn, project_questionnaire_path(original_conn, :update, project, questionnaire), questionnaire: %{steps: steps, settings: %{}}
      id = json_response(conn, 200)["data"]["id"]
      assert id

      vars = (Questionnaire
      |> Repo.get!(id)
      |> Repo.preload(:questionnaire_variables)).questionnaire_variables
      assert length(vars) == 1
    end
  end

  describe "update:" do
    test "updates and renders chosen resource when data is valid", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, project: project)
      conn = put conn, project_questionnaire_path(conn, :update, project, questionnaire), questionnaire: @valid_attrs
      assert json_response(conn, 200)["data"]["id"]
      assert Repo.get_by(Questionnaire, @valid_attrs)
    end

    test "rejects update if the questionnaire doesn't belong to the current user", %{conn: conn} do
      questionnaire = insert(:questionnaire)
      assert_error_sent :forbidden, fn ->
        put conn, project_questionnaire_path(conn, :update, questionnaire.project, questionnaire), questionnaire: @invalid_attrs
      end
    end

    test "rejects update for a project reader", %{conn: conn, user: user} do
      project = create_project_for_user(user, level: "reader")
      questionnaire = insert(:questionnaire, project: project)
      assert_error_sent :forbidden, fn ->
        put conn, project_questionnaire_path(conn, :update, questionnaire.project, questionnaire), questionnaire: @invalid_attrs
      end
    end

    test "rejects update if project is archived", %{conn: conn, user: user} do
      project = create_project_for_user(user, archived: true)
      questionnaire = insert(:questionnaire, project: project)
      assert_error_sent :forbidden, fn ->
        put conn, project_questionnaire_path(conn, :update, questionnaire.project, questionnaire), questionnaire: @valid_attrs
      end
    end

    test "rejects update for a snaphost", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, project: project)
      snapshot = insert(:questionnaire, project: project, snapshot_of: questionnaire.id)
      assert_error_sent :not_found, fn ->
        put conn, project_questionnaire_path(conn, :update, questionnaire.project, snapshot), questionnaire: @valid_attrs
      end
    end

    test "updates project updated_at when questionnaire is updated", %{conn: conn, user: user}  do
      datetime = Ecto.DateTime.cast!("2000-01-01 00:00:00")
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, project: project)
      put conn, project_questionnaire_path(conn, :update, project, questionnaire), questionnaire: @valid_attrs

      project = Project |> Repo.get(project.id)
      assert Ecto.DateTime.compare((project.updated_at |> NaiveDateTime.to_erl |> Ecto.DateTime.from_erl), datetime) == :gt
    end

    test "updates and creates variables", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, project: project)

      %Ask.QuestionnaireVariable{
        project_id: questionnaire.project_id,
        questionnaire_id: questionnaire.id,
        name: "Gonna be erased",
      } |> Repo.insert!

      conn = put conn, project_questionnaire_path(conn, :update, project, questionnaire), questionnaire: %{steps: @dummy_steps, settings: %{}}
      assert json_response(conn, 200)["data"]["id"]

      vars = (Questionnaire
      |> Repo.get!(questionnaire.id)
      |> Repo.preload(:questionnaire_variables)).questionnaire_variables
      assert length(vars) == 4
    end

    test "updates survey ready state when valid changes", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, project: project, valid: true)
      survey = insert(:survey, project: project, questionnaires: [questionnaire], state: "ready")

      put conn, project_questionnaire_path(conn, :update, project, questionnaire), questionnaire: %{"valid" => false, steps: [], settings: %{}}

      survey = Ask.Survey |> Repo.get!(survey.id)
      assert survey.state == "not_ready"
    end

    test "updates survey ready state when mode changes", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, project: project)
      survey = insert(:survey, project: project, questionnaires: [questionnaire], state: "ready")

      put conn, project_questionnaire_path(conn, :update, project, questionnaire), questionnaire: %{"modes" => ["ivr"], steps: [], settings: %{}}

      survey = Ask.Survey |> Repo.get!(survey.id)
      assert survey.state == "not_ready"
    end
  end

  describe "update translations" do
    test "creates no translations", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, project: project)

      steps = []
      put conn, project_questionnaire_path(conn, :update, project, questionnaire), questionnaire: %{steps: steps, quota_completed_steps: [], settings: %{}}

      assert (Translation |> Repo.all |> length) == 0
    end

    test "creates translations for one sms prompt", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, project: project, quota_completed_steps: nil)

      steps = [
        multiple_choice_step(
          id: "aaa",
          title: "Title",
          prompt: %{
            "en" => %{"sms" => "EN 1"},
            "es" => %{"sms" => "ES 1"},
          },
          store: "X",
          choices: []
        )
      ]
      conn = put conn, project_questionnaire_path(conn, :update, project, questionnaire), questionnaire: %{steps: steps, quota_completed_steps: nil, settings: %{}}
      assert json_response(conn, 200)["data"]["id"]

      translations = Translation |> Repo.all
      assert (translations |> length) == 1

      t = hd(translations)
      assert t.project_id == project.id
      assert t.questionnaire_id == questionnaire.id
      assert t.mode == "sms"
      assert t.source_lang == "en"
      assert t.source_text == "EN 1"
      assert t.target_lang == "es"
      assert t.target_text == "ES 1"
    end

    test "creates translations when no translation", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, project: project, quota_completed_steps: nil)

      steps = [
        multiple_choice_step(
          id: "aaa",
          title: "Title",
          prompt: %{
            "en" => %{"sms" => "EN 1"},
          },
          store: "X",
          choices: []
        )
      ]
      conn = put conn, project_questionnaire_path(conn, :update, project, questionnaire), questionnaire: %{steps: steps, quota_completed_steps: nil, settings: %{}}
      assert json_response(conn, 200)["data"]["id"]

      translations = Translation |> Repo.all
      assert (translations |> length) == 1

      t = hd(translations)
      assert t.project_id == project.id
      assert t.questionnaire_id == questionnaire.id
      assert t.mode == "sms"
      assert t.source_lang == "en"
      assert t.source_text == "EN 1"
      assert t.target_lang == nil
      assert t.target_text == nil
    end

    test "creates and recreates translations for other pieces", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, project: project, quota_completed_steps: nil)

      # Multiple additions

      steps = [
        multiple_choice_step(
          id: "aaa",
          title: "Title",
          prompt: %{
            "en" => %{"sms" => "EN 1", "ivr" => %{"text" => "EN 2", "audio_source": "tts"}},
            "es" => %{"sms" => "ES 1"},
            "fr" => %{"sms" => "", "ivr" => %{"text" => "FR 2", "audio_source": "tts"}},
          },
          store: "X",
          choices: [
            choice(value: "", responses: %{
              "sms" => %{
                "en" => ["EN 3", "EN 4"],
                "es" => ["ES 3", "ES 4"],
                "fr" => [""],
              },
            })
          ]
        )
      ]
      quota_completed_steps = [%{
        "id" => "quota-completed-step",
        "type" => "explanation",
        "title" => "Completed",
        "prompt" => %{
          "en" => %{"sms" => "EN 5", "ivr" => %{"text" => "EN 6", "audio_source": "tts"}},
          "es" => %{"sms" => "ES 5"},
          "fr" => %{"sms" => "", "ivr" => %{"text" => "FR 6", "audio_source": "tts"}},
        },
        "skip_logic" => nil
      }]

      original_conn = conn

      conn = put conn, project_questionnaire_path(conn, :update, project, questionnaire),
        questionnaire: %{steps: steps, quota_completed_steps: quota_completed_steps, settings: %{}}
      assert json_response(conn, 200)["data"]["id"]

      translations = Translation
      |> Repo.all
      |> Enum.map(&{&1.mode, &1.scope, &1.source_lang, &1.source_text, &1.target_lang, &1.target_text})
      |> Enum.sort

      expected = [
        {"sms", "prompt", "en", "EN 1", "es", "ES 1"},
        {"ivr", "prompt", "en", "EN 2", "fr", "FR 2"},
        {"sms", "response", "en", "EN 3, EN 4", "es", "ES 3, ES 4"},
        {"sms", "prompt", "en", "EN 5", "es", "ES 5"},
        {"ivr", "prompt", "en", "EN 6", "fr", "FR 6"},
      ] |> Enum.sort

      assert translations == expected

      # Additions and deletions

      steps = [
        multiple_choice_step(
          id: "aaa",
          title: "Title",
          prompt: %{
            "en" => %{"sms" => "EN 1", "ivr" => %{"text" => "EN 2", "audio_source": "tts"}},
            "es" => %{"sms" => ""},
            "fr" => %{"sms" => "", "ivr" => %{"text" => "FR 2 (NEW)", "audio_source": "tts"}},
          },
          store: "X",
          choices: [
            choice(value: "", responses: %{
              "sms" => %{
                "en" => ["EN 3", "EN 4"],
                "es" => ["ES 3", "ES 4"],
                "fr" => ["FR 3", "FR 4"],
              },
            }),
            choice(value: "", responses: %{
              "sms" => %{
                "en" => ["EN 3", "EN 4"],
                "es" => ["ES 10"],
                "fr" => ["FR 3", "FR 4"],
              },
            })
          ]
        )
      ]

      conn = put original_conn, project_questionnaire_path(conn, :update, project, questionnaire),
        questionnaire: %{steps: steps, quota_completed_steps: quota_completed_steps, settings: %{}}
      assert json_response(conn, 200)["data"]["id"]

      translations = Translation
      |> Repo.all
      |> Enum.map(&{&1.mode, &1.scope, &1.source_lang, &1.source_text, &1.target_lang, &1.target_text})
      |> Enum.sort

      expected = [
        {"sms", "prompt", "en", "EN 1", nil, nil},
        {"ivr", "prompt", "en", "EN 2", "fr", "FR 2 (NEW)"},
        {"sms", "response", "en", "EN 3, EN 4", "es", "ES 10"},
        {"sms", "response", "en", "EN 3, EN 4", "es", "ES 3, ES 4"},
        {"sms", "response", "en", "EN 3, EN 4", "fr", "FR 3, FR 4"},
        {"sms", "prompt", "en", "EN 5", "es", "ES 5"},
        {"ivr", "prompt", "en", "EN 6", "fr", "FR 6"},
      ] |> Enum.sort

      assert translations == expected

      # Single change (optimization)

      steps = [
        multiple_choice_step(
          id: "aaa",
          title: "Title",
          prompt: %{
            "en" => %{"sms" => "EN 1", "ivr" => %{"text" => "EN 2", "audio_source": "tts"}},
            "es" => %{"sms" => ""},
            "fr" => %{"sms" => "", "ivr" => %{"text" => "FR 2 (NEW)", "audio_source": "tts"}},
          },
          store: "X",
          choices: [
            choice(value: "", responses: %{
              "sms" => %{
                "en" => ["EN 3", "EN 4"],
                "es" => ["ES 3", "ES 4"],
                "fr" => ["FR 3", "FR 4"],
              },
            }),
            choice(value: "", responses: %{
              "sms" => %{
                "en" => ["EN 3", "EN 4"],
                "es" => ["ES 9"],
                "fr" => ["FR 3", "FR 4"],
              },
            })
          ]
        )
      ]

      conn = put original_conn, project_questionnaire_path(conn, :update, project, questionnaire),
        questionnaire: %{steps: steps, quota_completed_steps: quota_completed_steps, settings: %{}}
      assert json_response(conn, 200)["data"]["id"]

      translations = Translation
      |> Repo.all
      |> Enum.map(&{&1.mode, &1.scope, &1.source_lang, &1.source_text, &1.target_lang, &1.target_text})
      |> Enum.sort

      expected = [
        {"sms", "prompt", "en", "EN 1", nil, nil},
        {"ivr", "prompt", "en", "EN 2", "fr", "FR 2 (NEW)"},
        {"sms", "response", "en", "EN 3, EN 4", "es", "ES 9"},
        {"sms", "response", "en", "EN 3, EN 4", "es", "ES 3, ES 4"},
        {"sms", "response", "en", "EN 3, EN 4", "fr", "FR 3, FR 4"},
        {"sms", "prompt", "en", "EN 5", "es", "ES 5"},
        {"ivr", "prompt", "en", "EN 6", "fr", "FR 6"},
      ] |> Enum.sort

      assert translations == expected
    end
  end

  describe "delete:" do
    test "deletes chosen resource", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, project: project)
      conn = delete conn, project_questionnaire_path(conn, :delete, project, questionnaire)
      assert response(conn, 204)

      questionnaire = Repo.get(Questionnaire, questionnaire.id)
      assert questionnaire.deleted == true
    end

    test "rejects delete if the questionnaire doesn't belong to the current user", %{conn: conn} do
      questionnaire = insert(:questionnaire)
      assert_error_sent :forbidden, fn ->
        delete conn, project_questionnaire_path(conn, :delete, questionnaire.project, questionnaire)
      end
    end

    test "rejects delete for a project reader", %{conn: conn, user: user} do
      project = create_project_for_user(user, level: "reader")
      questionnaire = insert(:questionnaire, project: project)
      assert_error_sent :forbidden, fn ->
        delete conn, project_questionnaire_path(conn, :delete, questionnaire.project, questionnaire)
      end
    end

    test "rejects delete if project is archived", %{conn: conn, user: user} do
      project = create_project_for_user(user, archived: true)
      questionnaire = insert(:questionnaire, project: project)
      assert_error_sent :forbidden, fn ->
        delete conn, project_questionnaire_path(conn, :delete, questionnaire.project, questionnaire)
      end
    end

    test "rejects delete for a snapshot", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, project: project)
      snapshot = insert(:questionnaire, project: project, snapshot_of: questionnaire.id)
      assert_error_sent :not_found, fn ->
        delete conn, project_questionnaire_path(conn, :delete, questionnaire.project, snapshot)
      end
    end

    test "updates project updated_at when questionnaire is deleted", %{conn: conn, user: user}  do
      datetime = Ecto.DateTime.cast!("2000-01-01 00:00:00")
      project = insert(:project, updated_at: datetime)
      insert(:project_membership, user: user, project: project, level: "owner")
      questionnaire = insert(:questionnaire, project: project)
      delete conn, project_questionnaire_path(conn, :delete, project, questionnaire)

      project = Project |> Repo.get(project.id)
      assert Ecto.DateTime.compare((project.updated_at |> NaiveDateTime.to_erl |> Ecto.DateTime.from_erl), datetime) == :gt
    end

    test "remove reference from survey when questionnaire is deleted", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, project: project)
      survey = insert(:survey, project: project, questionnaires: [questionnaire], state: "ready")

      delete conn, project_questionnaire_path(conn, :delete, project, questionnaire)

      survey = Ask.Survey |> preload(:questionnaires) |> Repo.get!(survey.id)
      assert survey.questionnaires == []
      assert survey.state == "not_ready"
    end
  end

  describe "activity logs" do
    setup %{conn: conn} do
      remote_ip = {192, 168, 0, 128}
      conn = %{conn | remote_ip: remote_ip}
      {:ok, conn: conn, remote_ip: remote_ip}
    end

    test "generates log after creating a questionnaire", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      # post conn, project_questionnaire_path(conn, :create, project.id)
      post conn, project_questionnaire_path(conn, :create, project.id), questionnaire: @valid_attrs

      log = ActivityLog |> Repo.one
      questionnaire = Questionnaire |> Repo.one

      assert_questionnaire_log(%{log: log, user: user, project: project, questionnaire: questionnaire, action: "create", remote_ip: "192.168.0.128", metadata: nil})
    end

    test "generates log after deleting a questionnaire", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, project: project)

      delete conn, project_questionnaire_path(conn, :delete, questionnaire.project, questionnaire)
      log = ActivityLog |> Repo.one

      assert_questionnaire_log(%{log: log, user: user, project: project, questionnaire: questionnaire, action: "delete", remote_ip: "192.168.0.128", metadata: %{"questionnaire_name" => questionnaire.name}})
    end

    test "generates rename log if name changed", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, project: project)

      put conn, project_questionnaire_path(conn, :update, project, questionnaire), questionnaire: @valid_attrs
      log = ActivityLog|> Repo.all |> Enum.find(fn(x) -> x.action == "rename" end)

      assert_questionnaire_log(%{log: log, user: user, project: project, questionnaire: questionnaire, action: "rename", remote_ip: "192.168.0.128", metadata: %{"old_questionnaire_name" => questionnaire.name, "new_questionnaire_name" => "some content"}})
    end

    test "generates log for changes in modes", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, project: project, modes: ["sms", "ivr"])

      put conn, project_questionnaire_path(conn, :update, project, questionnaire), questionnaire:  Map.merge(@valid_attrs, %{modes: ["sms", "mobileweb"]})

      log = ActivityLog|> Repo.all |> Enum.find(fn(x) -> x.action == "add_mode" end)
      log_2 = ActivityLog|> Repo.all |> Enum.find(fn(x) -> x.action == "remove_mode" end)

      assert_questionnaire_log(%{log: log, user: user, project: project, questionnaire: questionnaire, action: "add_mode", remote_ip: "192.168.0.128", metadata: %{"mode" => "mobileweb"}})

      assert_questionnaire_log(%{log: log_2, user: user, project: project, questionnaire: questionnaire, action: "remove_mode", remote_ip: "192.168.0.128", metadata: %{"mode" => "ivr"}})
    end

    test "generates log for changes in languages", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      questionnaire = insert(:questionnaire, project: project, languages: ["en", "fr"])

      conn = put conn, project_questionnaire_path(conn, :update, project, questionnaire), questionnaire:  Map.merge(@valid_attrs, %{languages: ["es", "en"]})
      assert response(conn, 200)

      log_1 = ActivityLog |> Repo.all |> Enum.find(fn(x) -> x.action == "add_language" end)
      log_2 = ActivityLog |> Repo.all |> Enum.find(fn(x) -> x.action == "remove_language" end)

      assert_questionnaire_log(%{log: log_1, user: user, project: project, questionnaire: questionnaire, action: "add_language", remote_ip: "192.168.0.128", metadata: %{"language" => "es"}})
      assert_questionnaire_log(%{log: log_2, user: user, project: project, questionnaire: questionnaire, action: "remove_language", remote_ip: "192.168.0.128", metadata: %{"language" => "fr"}})
    end

    test "generates log when two steps are created", %{conn: conn, user: user} do
      project = create_project_for_user(user)

      all_steps = [first_step, second_step | tail_steps] = @dummy_steps

      questionnaire = insert(:questionnaire, project: project, name: @valid_attrs.name, steps: tail_steps)

      put conn, project_questionnaire_path(conn, :update, project, questionnaire), questionnaire:  Map.merge(@valid_attrs, %{steps: all_steps})

      all_logs = ActivityLog|> Repo.all

      log_1 = all_logs |> Enum.find(fn(x) -> x.action == "create_step" && x.metadata["step_id"] == first_step["id"]  end)
      log_2 = all_logs |> Enum.find(fn(x) -> x.action == "create_step" && x.metadata["step_id"] == second_step["id"]  end)

      assert_questionnaire_log(%{log: log_1, user: user, project: project, questionnaire: questionnaire, action: "create_step", remote_ip: "192.168.0.128", metadata: %{"step_id" => first_step["id"], "step_title" => first_step["title"], "step_type" => first_step["type"]}})

      assert_questionnaire_log(%{log: log_2, user: user, project: project, questionnaire: questionnaire, action: "create_step", remote_ip: "192.168.0.128", metadata: %{"step_id" => second_step["id"], "step_title" => second_step["title"], "step_type" => second_step["type"]}})

      assert length(all_logs) == 2
    end

    test "generates log when two steps are deleted", %{conn: conn, user: user} do
      project = create_project_for_user(user)

      all_steps = [first_step, second_step | tail_steps] = @dummy_steps

      questionnaire = insert(:questionnaire, project: project, name: @valid_attrs.name, steps: all_steps)

      put conn, project_questionnaire_path(conn, :update, project, questionnaire), questionnaire:  Map.merge(@valid_attrs, %{steps: tail_steps})

      all_logs = ActivityLog|> Repo.all

      log_1 = all_logs |> Enum.find(fn(x) -> x.action == "delete_step" && x.metadata["step_id"] == first_step["id"]  end)
      log_2 = all_logs |> Enum.find(fn(x) -> x.action == "delete_step" && x.metadata["step_id"] == second_step["id"]  end)

      assert_questionnaire_log(%{log: log_1, user: user, project: project, questionnaire: questionnaire, action: "delete_step", remote_ip: "192.168.0.128", metadata: %{"step_id" => first_step["id"], "step_title" => first_step["title"], "step_type" => first_step["type"]}})

      assert_questionnaire_log(%{log: log_2, user: user, project: project, questionnaire: questionnaire, action: "delete_step", remote_ip: "192.168.0.128", metadata: %{"step_id" => second_step["id"], "step_title" => second_step["title"], "step_type" => second_step["type"]}})

      assert length(all_logs) == 2
    end

    test "generates log when two steps are renamed", %{conn: conn, user: user} do
      project = create_project_for_user(user)

      all_steps = [first_step, second_step | tail_steps] = @dummy_steps

      questionnaire = insert(:questionnaire, project: project, name: @valid_attrs.name, steps: all_steps)

      new_first_step = %{first_step | "title" => "new title"}
      new_second_step = %{second_step | "title" => "other new title"}

      put conn, project_questionnaire_path(conn, :update, project, questionnaire), questionnaire:  %{@valid_attrs | steps: [new_first_step, new_second_step | tail_steps]}

      all_logs = ActivityLog|> Repo.all

      log_1 = all_logs |> Enum.find(fn(x) -> x.action == "rename_step" && x.metadata["step_id"] == first_step["id"]  end)
      log_2 = all_logs |> Enum.find(fn(x) -> x.action == "rename_step" && x.metadata["step_id"] == second_step["id"]  end)

      assert_questionnaire_log(%{log: log_1, user: user, project: project, questionnaire: questionnaire, action: "rename_step", remote_ip: "192.168.0.128", metadata: %{"step_id" => first_step["id"], "old_step_title" => first_step["title"], "new_step_title" => new_first_step["title"]}})

      assert_questionnaire_log(%{log: log_2, user: user, project: project, questionnaire: questionnaire, action: "rename_step", remote_ip: "192.168.0.128", metadata: %{"step_id" => second_step["id"], "old_step_title" => second_step["title"], "new_step_title" => new_second_step["title"]}})

      assert length(all_logs) == 2
    end

    test "generates log when a step is renamed and other is deleted", %{conn: conn, user: user} do
      project = create_project_for_user(user)

      all_steps = [first_step, second_step | tail_steps] = @dummy_steps

      questionnaire = insert(:questionnaire, project: project, name: @valid_attrs.name, steps: all_steps)

      new_first_step = %{first_step | "title" => "new title"}

      put conn, project_questionnaire_path(conn, :update, project, questionnaire), questionnaire:  %{@valid_attrs | steps: [new_first_step | tail_steps]}

      all_logs = ActivityLog|> Repo.all

      log_1 = all_logs |> Enum.find(fn(x) -> x.action == "rename_step" && x.metadata["step_id"] == first_step["id"]  end)
      log_2 = all_logs |> Enum.find(fn(x) -> x.action == "delete_step" && x.metadata["step_id"] == second_step["id"]  end)

      assert_questionnaire_log(%{log: log_1, user: user, project: project, questionnaire: questionnaire, action: "rename_step", remote_ip: "192.168.0.128", metadata: %{"step_id" => first_step["id"], "old_step_title" => first_step["title"], "new_step_title" => new_first_step["title"]}})

      assert_questionnaire_log(%{log: log_2, user: user, project: project, questionnaire: questionnaire, action: "delete_step", remote_ip: "192.168.0.128", metadata: %{"step_id" => second_step["id"], "step_title" => second_step["title"], "step_type" => second_step["type"]}})

      assert length(all_logs) == 2
    end

    test "generates log when two steps are edited", %{conn: conn, user: user} do
      project = create_project_for_user(user)

      all_steps = [first_step, second_step | tail_steps] = @dummy_steps

      questionnaire = insert(:questionnaire, project: project, name: @valid_attrs.name, steps: all_steps)

      new_first_step = %{first_step | "store" => "new store"}
      new_second_step = %{second_step | "store" => "other new store", "title" => "new title"}

      put conn, project_questionnaire_path(conn, :update, project, questionnaire), questionnaire:  %{@valid_attrs | steps: [new_first_step, new_second_step | tail_steps]}

      all_logs = ActivityLog|> Repo.all

      log_1 = all_logs |> Enum.find(fn(x) -> x.action == "edit_step" && x.metadata["step_id"] == first_step["id"]  end)
      log_2 = all_logs |> Enum.find(fn(x) -> x.action == "edit_step" && x.metadata["step_id"] == second_step["id"]  end)
      log_3 = all_logs |> Enum.find(fn(x) -> x.action == "rename_step" && x.metadata["step_id"] == second_step["id"]  end)

      assert_questionnaire_log(%{log: log_1, user: user, project: project, questionnaire: questionnaire, action: "edit_step", remote_ip: "192.168.0.128", metadata: %{"step_id" => first_step["id"], "step_title" => first_step["title"]}})

      assert_questionnaire_log(%{log: log_2, user: user, project: project, questionnaire: questionnaire, action: "edit_step", remote_ip: "192.168.0.128", metadata: %{"step_id" => second_step["id"], "step_title" => new_second_step["title"]}})

      assert_questionnaire_log(%{log: log_3, user: user, project: project, questionnaire: questionnaire, action: "rename_step", remote_ip: "192.168.0.128", metadata: %{"step_id" => second_step["id"], "old_step_title" => second_step["title"], "new_step_title" => new_second_step["title"]}})

      assert length(all_logs) == 3
    end

  end

  defp assert_log(log, user, project, questionnaire, action, remote_ip) do
    assert log.project_id == project.id
    assert log.user_id == user.id
    assert log.entity_id == questionnaire.id
    assert log.entity_type == "questionnaire"
    assert log.action == action
    assert log.remote_ip == remote_ip
  end

  defp assert_questionnaire_log(%{log: log, user: user, project: project, questionnaire: questionnaire, action: action, remote_ip: remote_ip, metadata: metadata}) do
    assert_log(log, user, project, questionnaire, action, remote_ip)
    assert log.metadata == metadata
  end

end
