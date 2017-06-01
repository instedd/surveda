defmodule Ask.SurveyControllerTest do
  use Ask.ConnCase
  use Ask.TestHelpers
  use Ask.DummySteps

  alias Ask.{Survey, Project, RespondentGroup, Respondent, Response, Channel, SurveyQuestionnaire, RespondentDispositionHistory, TestChannel, RespondentGroupChannel}
  alias Ask.Runtime.{Flow, Session}
  alias Ask.Runtime.SessionModeProvider

  @valid_attrs %{name: "some content"}
  @invalid_attrs %{state: ""}

  setup %{conn: conn} do
    user = insert(:user)
    conn = conn
      |> put_private(:test_user, user)
      |> put_req_header("accept", "application/json")
    {:ok, conn: conn, user: user}
  end

  describe "index" do
    test "returns code 200 and empty list if there are no entries", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      conn = get conn, project_survey_path(conn, :index, project.id)
      assert json_response(conn, 200)["data"] == []
    end

    test "lists surveys", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)
      conn = get conn, project_survey_path(conn, :index, project.id)
      assert json_response(conn, 200)["data"] == [
        %{"cutoff" => survey.cutoff, "id" => survey.id, "mode" => survey.mode, "name" => survey.name, "project_id" => project.id, "state" => "not_ready", "exit_code" => nil, "exit_message" => nil, "timezone" => "UTC", "next_schedule_time" => nil, "updated_at" => Ecto.DateTime.to_iso8601(survey.updated_at)}
      ]
    end

    test "returns 404 when the project does not exist", %{conn: conn} do
      assert_error_sent 404, fn ->
        get conn, project_survey_path(conn, :index, -1)
      end
    end

    test "forbid index access if the project does not belong to the current user", %{conn: conn} do
      survey = insert(:survey)
      assert_error_sent :forbidden, fn ->
        get conn, project_survey_path(conn, :index, survey.project)
      end
    end
  end

  describe "show" do
    test "shows chosen resource", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)
      conn = get conn, project_survey_path(conn, :show, project, survey)
      assert json_response(conn, 200)["data"] == %{"id" => survey.id,
        "name" => survey.name,
        "mode" => survey.mode,
        "project_id" => survey.project_id,
        "questionnaire_ids" => [],
        "cutoff" => nil,
        "count_partial_results" => false,
        "state" => "not_ready",
        "exit_code" => nil,
        "exit_message" => nil,
        "respondents_count" => 0,
        "schedule_day_of_week" => %{
          "fri" => true, "mon" => true, "sat" => true, "sun" => true, "thu" => true, "tue" => true, "wed" => true
        },
        "schedule_start_time" => "00:00:00",
        "schedule_end_time" => "23:59:59",
        "timezone" => "UTC",
        "started_at" => "",
        "ivr_retry_configuration" => nil,
        "sms_retry_configuration" => nil,
        "mobileweb_retry_configuration" => nil,
        "fallback_delay" => nil,
        "updated_at" => Ecto.DateTime.to_iso8601(survey.updated_at),
        "quotas" => %{
          "vars" => [],
          "buckets" => []
        },
        "comparisons" => [],
        "timezone" => "UTC",
        "next_schedule_time" => nil,
      }
    end

    test "shows chosen resource with buckets", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project, quota_vars: ["gender", "smokes"])
      insert(:quota_bucket, survey: survey, condition: %{gender: "male", smokes: "no"}, quota: 10, count: 3)
      insert(:quota_bucket, survey: survey, condition: %{gender: "male", smokes: "yes"}, quota: 20)
      insert(:quota_bucket, survey: survey, condition: %{gender: "female", smokes: "no"}, quota: 30, count: 1)
      insert(:quota_bucket, survey: survey, condition: %{gender: "female", smokes: "yes"}, quota: 40)
      conn = get conn, project_survey_path(conn, :show, project, survey)
      assert json_response(conn, 200)["data"] == %{"id" => survey.id,
        "name" => survey.name,
        "mode" => survey.mode,
        "project_id" => survey.project_id,
        "questionnaire_ids" => [],
        "cutoff" => nil,
        "count_partial_results" => false,
        "state" => "not_ready",
        "exit_code" => nil,
        "exit_message" => nil,
        "respondents_count" => 0,
        "schedule_day_of_week" => %{
          "fri" => true, "mon" => true, "sat" => true, "sun" => true, "thu" => true, "tue" => true, "wed" => true
        },
        "schedule_start_time" => "00:00:00",
        "schedule_end_time" => "23:59:59",
        "timezone" => "UTC",
        "started_at" => "",
        "ivr_retry_configuration" => nil,
        "sms_retry_configuration" => nil,
        "mobileweb_retry_configuration" => nil,
        "fallback_delay" => nil,
        "updated_at" => Ecto.DateTime.to_iso8601(survey.updated_at),
        "quotas" => %{
          "vars" => ["gender", "smokes"],
          "buckets" => [
            %{
              "condition" => [%{"store" => "smokes", "value" => "no"}, %{"store" => "gender", "value" => "male"}],
              "quota" => 10,
              "count" => 3
            },
            %{
              "condition" => [%{"store" => "smokes", "value" => "yes"}, %{"store" => "gender", "value" => "male"}],
              "quota" => 20,
              "count" => 0
            },
            %{
              "condition" => [%{"store" => "smokes", "value" => "no"}, %{"store" => "gender", "value" => "female"}],
              "quota" => 30,
              "count" => 1
            },
            %{
              "condition" => [%{"store" => "smokes", "value" => "yes"}, %{"store" => "gender", "value" => "female"}],
              "quota" => 40,
              "count" => 0
            },
          ]
        },
        "comparisons" => [],
        "next_schedule_time" => nil
      }
    end

    test "renders page not found when id is nonexistent", %{conn: conn} do
      assert_error_sent 404, fn ->
        get conn, project_survey_path(conn, :show, -1, -1)
      end
    end

    test "forbid access to survey if the project does not belong to the current user", %{conn: conn} do
      survey = insert(:survey)
      assert_error_sent :forbidden, fn ->
        get conn, project_survey_path(conn, :show, survey.project, survey)
      end
    end
  end

  describe "create" do
    test "creates and renders resource when data is valid", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      conn = post conn, project_survey_path(conn, :create, project.id)
      assert json_response(conn, 201)["data"]["id"]
      assert Repo.get_by(Survey, %{project_id: project.id})
    end

    test "forbids creation of survey for a project that belongs to another user", %{conn: conn} do
      project = insert(:project)
      assert_error_sent :forbidden, fn ->
        post conn, project_survey_path(conn, :create, project.id), survey: @valid_attrs
      end
    end

    test "forbids creation of survey for a project reader", %{conn: conn, user: user} do
      project = create_project_for_user(user, level: "reader")
      assert_error_sent :forbidden, fn ->
        post conn, project_survey_path(conn, :create, project.id), survey: @valid_attrs
      end
    end

    test "updates project updated_at when survey is created", %{conn: conn, user: user} do
      datetime = Ecto.DateTime.cast!("2000-01-01 00:00:00")
      project = create_project_for_user(user)
      post conn, project_survey_path(conn, :create, project.id)

      project = Project |> Repo.get(project.id)
      assert Ecto.DateTime.compare(project.updated_at, datetime) == :gt
    end
  end

  describe "update" do
    test "updates and renders chosen resource when data is valid", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: @valid_attrs
      assert json_response(conn, 200)["data"]["id"]
      assert Repo.get_by(Survey, @valid_attrs)
    end

    test "updates schedule when data is valid", %{conn: conn, user: user} do
      [project, questionnaire, _] = prepare_for_state_update(user)

      survey = insert(:survey, project: project, questionnaires: [questionnaire])

      attrs = %{schedule_day_of_week: %{sun: true, mon: true, tue: true, wed: true, thu: true, fri: false, sat: true}}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["schedule_day_of_week"]["sun"] == true
    end

    test "updates cutoff when channels are included in params", %{conn: conn, user: user} do
      [project, questionnaire, channel] = prepare_for_state_update(user)

      survey = insert(:survey, project: project, questionnaires: [questionnaire])
      create_group(survey, channel)

      attrs = %{cutoff: 4, channels: [channel.id]}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["cutoff"] == 4
    end

    test "does not update chosen resource and renders errors when data is invalid", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)
      conn = put conn, project_survey_path(conn, :update, survey.project, survey), survey: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end

    test "saves quota_buckets and quota_vars", %{conn: conn, user: user} do
      [project, questionnaire, _] = prepare_for_state_update(user)

      survey = insert(:survey, project: project, questionnaires: [questionnaire])

      attrs = %{quotas: %{vars: ["Smokes", "Exercises"], buckets: [
        %{
          "condition" => [%{"store" => "Exercises", "value" => "No"}, %{"store" => "Smokes", "value" => "No"}],
          "quota" => 10,
          "count" => 3
        },
        %{
          "condition" => [%{"store" => "Exercises", "value" => "No"}, %{"store" => "Smokes", "value" => "Yes"}],
          "quota" => 20
        },
        %{
          "condition" => [%{"store" => "Exercises", "value" => "Yes"}, %{"store" => "Smokes", "value" => "No"}],
          "quota" => 30
        },
        %{
          "condition" => [%{"store" => "Exercises", "value" => "Yes"}, %{"store" => "Smokes", "value" => "Yes"}],
          "quota" => 40
        },
      ]}}
      conn2 = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn2, 200)["data"]["quotas"]["vars"] == ["Smokes", "Exercises"]
      assert json_response(conn2, 200)["data"]["quotas"]["buckets"] == [
        %{
          "condition" => [%{"store" => "Smokes", "value" => "No"}, %{"store" => "Exercises", "value" => "No"}],
          "quota" => 10,
          "count" => 3
        },
        %{
          "condition" => [%{"store" => "Smokes", "value" => "Yes"}, %{"store" => "Exercises", "value" => "No"}],
          "quota" => 20,
          "count" => 0
        },
        %{
          "condition" => [%{"store" => "Smokes", "value" => "No"}, %{"store" => "Exercises", "value" => "Yes"}],
          "quota" => 30,
          "count" => 0
        },
        %{
          "condition" => [%{"store" => "Smokes", "value" => "Yes"}, %{"store" => "Exercises", "value" => "Yes"}],
          "quota" => 40,
          "count" => 0
        },
      ]

      conn = get conn, project_survey_path(conn, :show, project, survey)
      assert json_response(conn, 200)["data"]["quotas"] == %{
        "vars" => ["Smokes", "Exercises"],
        "buckets" => [
          %{
            "condition" => [%{"store" => "Smokes", "value" => "No"}, %{"store" => "Exercises", "value" => "No"}],
            "quota" => 10,
            "count" => 3
          },
          %{
            "condition" => [%{"store" => "Smokes", "value" => "Yes"}, %{"store" => "Exercises", "value" => "No"}],
            "quota" => 20,
            "count" => 0
          },
          %{
            "condition" => [%{"store" => "Smokes", "value" => "No"}, %{"store" => "Exercises", "value" => "Yes"}],
            "quota" => 30,
            "count" => 0
          },
          %{
            "condition" => [%{"store" => "Smokes", "value" => "Yes"}, %{"store" => "Exercises", "value" => "Yes"}],
            "quota" => 40,
            "count" => 0
          },
        ]
      }
    end

    test "replaces quota_buckets when vars are updated", %{conn: conn, user: user}  do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project, quota_vars: ["gender", "smokes"])
      insert(:quota_bucket, survey: survey, condition: %{gender: "male", smokes: "no"}, quota: 10, count: 3)
      insert(:quota_bucket, survey: survey, condition: %{gender: "male", smokes: "yes"}, quota: 20)
      insert(:quota_bucket, survey: survey, condition: %{gender: "female", smokes: "no"}, quota: 30, count: 1)
      insert(:quota_bucket, survey: survey, condition: %{gender: "female", smokes: "yes"}, quota: 40)

      attrs = %{quotas: %{vars: ["Exercises", "Smokes"], buckets: [
        %{
          "condition" => [%{"store" => "Exercises", "value" => "No"}, %{"store" => "Smokes", "value" => "No"}],
          "quota" => 10,
          "count" => 3
        },
        %{
          "condition" => [%{"store" => "Exercises", "value" => "No"}, %{"store" => "Smokes", "value" => "Yes"}],
          "quota" => 20
        },
        %{
          "condition" => [%{"store" => "Exercises", "value" => "Yes"}, %{"store" => "Smokes", "value" => "No"}],
          "quota" => 30
        },
        %{
          "condition" => [%{"store" => "Exercises", "value" => "Yes"}, %{"store" => "Smokes", "value" => "Yes"}],
          "quota" => 40
        },
      ]}}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["quotas"]["vars"] == ["Exercises", "Smokes"]
      assert json_response(conn, 200)["data"]["quotas"]["buckets"] == [
        %{
          "condition" => [%{"store" => "Smokes", "value" => "No"}, %{"store" => "Exercises", "value" => "No"}],
          "quota" => 10,
          "count" => 3
        },
        %{
          "condition" => [%{"store" => "Smokes", "value" => "Yes"}, %{"store" => "Exercises", "value" => "No"}],
          "quota" => 20,
          "count" => 0
        },
        %{
          "condition" => [%{"store" => "Smokes", "value" => "No"}, %{"store" => "Exercises", "value" => "Yes"}],
          "quota" => 30,
          "count" => 0
        },
        %{
          "condition" => [%{"store" => "Smokes", "value" => "Yes"}, %{"store" => "Exercises", "value" => "Yes"}],
          "quota" => 40,
          "count" => 0
        },
      ]
    end

    test "rejects update if the survey doesn't belong to the current user", %{conn: conn} do
      survey = insert(:survey)
      assert_error_sent :forbidden, fn ->
        put conn, project_survey_path(conn, :update, survey.project, survey), survey: @invalid_attrs
      end
    end

    test "rejects update for a project reader", %{conn: conn, user: user} do
      project = create_project_for_user(user, level: "reader")
      survey = insert(:survey, project: project)
      assert_error_sent :forbidden, fn ->
        put conn, project_survey_path(conn, :update, survey.project, survey), survey: @invalid_attrs
      end
    end

    test "fails if the schedule from is greater or equal to the to", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)
      attrs = Map.merge(@valid_attrs, %{schedule_start_time: "02:00:00", schedule_end_time: "01:00:00"})
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 422)["errors"] != %{}
    end

    test "schedule to and from are saved successfully", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)
      attrs = Map.merge(@valid_attrs, %{schedule_start_time: "01:00:00", schedule_end_time: "02:00:00"})
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)
      created_survey = Repo.get_by(Survey, %{project_id: project.id})
      {:ok, one_oclock} = Ecto.Time.cast("01:00:00")
      {:ok, two_oclock} = Ecto.Time.cast("02:00:00")
      assert created_survey.schedule_start_time == one_oclock
      assert created_survey.schedule_end_time == two_oclock
    end

    test "rejects update with correct error when cutoff field is greater than the max value", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)
      max_int = 2147483648
      attrs = Map.merge(@valid_attrs, %{cutoff: max_int})
      conn = put conn, project_survey_path(conn, :update, survey.project, survey), survey: attrs
      assert json_response(conn, 422)["errors"] != %{cutoff: "must be less than #{max_int}"}
    end

    test "rejects update with correct error when cutoff field is less than zero", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)
      attrs = Map.merge(@valid_attrs, %{cutoff: 0})
      conn = put conn, project_survey_path(conn, :update, survey.project, survey), survey: attrs
      assert json_response(conn, 422)["errors"] != %{cutoff: "must be greater than 0"}
    end

    test "updates project updated_at when survey is updated", %{conn: conn, user: user}  do
      datetime = Ecto.DateTime.cast!("2000-01-01 00:00:00")
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)
      put conn, project_survey_path(conn, :update, survey.project, survey), survey: %{name: "New name"}

      project = Project |> Repo.get(project.id)
      assert Ecto.DateTime.compare(project.updated_at, datetime) == :gt
    end
  end

  describe "delete" do
    test "deletes chosen resource", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)
      conn = delete conn, project_survey_path(conn, :delete, survey.project, survey)
      assert response(conn, 204)
      refute Repo.get(Survey, survey.id)
    end

    test "forbids delete if the project doesn't belong to the current user", %{conn: conn} do
      survey = insert(:survey)
      assert_error_sent :forbidden, fn ->
        delete conn, project_survey_path(conn, :delete, survey.project, survey)
      end
    end

    test "forbids delete for a project reader", %{conn: conn, user: user} do
      project = create_project_for_user(user, level: "reader")
      survey = insert(:survey, project: project)
      assert_error_sent :forbidden, fn ->
        delete conn, project_survey_path(conn, :delete, survey.project, survey)
      end
    end

    test "reject delete if the survey is running", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project, state: "running")
      conn = delete conn, project_survey_path(conn, :delete, survey.project, survey)
      assert response(conn, :bad_request)
      assert Survey |> Repo.get(survey.id)
    end

    test "updates project updated_at when survey is deleted", %{conn: conn, user: user}  do
      datetime = Ecto.DateTime.cast!("2000-01-01 00:00:00")
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)
      delete conn, project_survey_path(conn, :delete, survey.project, survey)

      project = Project |> Repo.get(project.id)
      assert Ecto.DateTime.compare(project.updated_at, datetime) == :gt
    end

    test "delete survey and all contents", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      survey = insert(:survey, project: project)
      channel = insert(:channel, user: user)
      group = create_group(survey, channel)
      respondent = add_respondent_to(group)
      response = insert(:response, respondent: respondent)
      questionnaire = insert(:questionnaire, project: project)
      survey_questionnaire = insert(:survey_questionnaire, survey: survey, questionnaire: questionnaire)
      history = insert(:respondent_disposition_history, respondent: respondent)

      delete conn, project_survey_path(conn, :delete, survey.project, survey)

      refute Survey |> Repo.get(survey.id)
      refute RespondentGroup |> Repo.get(group.id)
      refute Respondent |> Repo.get(respondent.id)
      refute Response |> Repo.get(response.id)
      refute SurveyQuestionnaire |> Repo.get(survey_questionnaire.id)
      refute RespondentDispositionHistory |> Repo.get(history.id)
    end
  end

  describe "changes the survey state when needed" do
    test "updates state when adding questionnaire", %{conn: conn, user: user} do
      [project, questionnaire, channel] = prepare_for_state_update(user)

      survey = insert(:survey, project: project, cutoff: 4, schedule_day_of_week: completed_schedule)
      create_group(survey, channel)

      attrs = %{questionnaire_ids: [questionnaire.id]}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)

      qs = (new_survey |> Repo.preload(:questionnaires)).questionnaires
      assert length(qs) == 1
      assert hd(qs).id == questionnaire.id

      assert new_survey.state == "ready"
    end

    test "updates state when selecting mode", %{conn: conn, user: user} do
      [project, questionnaire, channel] = prepare_for_state_update(user)

      survey = insert(:survey, project: project, questionnaires: [questionnaire], cutoff: 4, schedule_day_of_week: completed_schedule)
      create_group(survey, channel)

      attrs = %{mode: [["sms"]]}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)

      assert new_survey.state == "ready"
    end

    test "updates state when selecting mode, missing channel", %{conn: conn, user: user} do
      [project, questionnaire, channel] = prepare_for_state_update(user)

      survey = insert(:survey, project: project, questionnaires: [questionnaire], cutoff: 4, schedule_day_of_week: completed_schedule)
      create_group(survey, channel)

      attrs = %{mode: [["sms", "ivr"]]}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)

      assert new_survey.state == "not_ready"
    end

    test "updates state when selecting mode, missing channel, multiple modes", %{conn: conn, user: user} do
      [project, questionnaire, channel] = prepare_for_state_update(user)

      survey = insert(:survey, project: project, questionnaires: [questionnaire], cutoff: 4, schedule_day_of_week: completed_schedule)
      create_group(survey, channel)

      attrs = %{mode: [["sms"], ["sms", "ivr"]]}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)

      assert new_survey.state == "not_ready"
    end

    test "updates state when selecting mode, all channels", %{conn: conn, user: user} do
      [project, questionnaire, channel] = prepare_for_state_update(user)

      survey = insert(:survey, project: project, questionnaires: [questionnaire], cutoff: 4, schedule_day_of_week: completed_schedule)
      group = create_group(survey)

      channel2 = insert(:channel, user: user, type: "ivr")

      add_channel_to(group, channel)
      add_channel_to(group, channel2)

      attrs = %{mode: [["sms", "ivr"]]}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)

      assert new_survey.state == "ready"
    end

    test "updates state when adding cutoff", %{conn: conn, user: user} do
      [project, questionnaire, channel] = prepare_for_state_update(user)

      survey = insert(:survey, project: project, questionnaires: [questionnaire], schedule_day_of_week: completed_schedule, mode: [["sms"]])
      create_group(survey, channel)

      attrs = %{cutoff: 4}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)

      assert new_survey.state == "ready"
    end

    test "changes state to not_ready when an invalid retry attempt configuration is passed", %{conn: conn, user: user} do
      [project, questionnaire, channel] = prepare_for_state_update(user)

      survey = insert(:survey, project: project, cutoff: 4, schedule_day_of_week: completed_schedule, mode: [["sms"]], questionnaires: [questionnaire])
      create_group(survey, channel)

      attrs = %{sms_retry_configuration: "12j 13p 14q"}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)

      assert new_survey.state == "not_ready"
    end

    test "changes state to not_ready when an invalid fallback delay is passed", %{conn: conn, user: user} do
      [project, questionnaire, channel] = prepare_for_state_update(user)

      survey = insert(:survey, project: project, cutoff: 4, schedule_day_of_week: completed_schedule, mode: [["sms"]], questionnaires: [questionnaire])
      create_group(survey, channel)

      attrs = %{fallback_delay: "12j"}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)

      assert new_survey.state == "not_ready"
    end

    test "returns state to ready when a valid retry configuration is passed", %{conn: conn, user: user} do
      [project, questionnaire, channel] = prepare_for_state_update(user)

      survey = insert(:survey, project: project, cutoff: 4, schedule_day_of_week: completed_schedule, mode: [["sms"]], questionnaires: [questionnaire], sms_retry_configuration: "12j 13p 14q")
      create_group(survey, channel)

      new_survey = Repo.get(Survey, survey.id)
      assert new_survey.state == "not_ready"

      attrs = %{sms_retry_configuration: "5m 1h 2d"}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)

      assert new_survey.state == "ready"
    end

    test "updates state when adding a day in schedule", %{conn: conn, user: user} do
      [project, questionnaire, channel] = prepare_for_state_update(user)

      survey = insert(:survey, project: project, questionnaires: [questionnaire], cutoff: 3, mode: [["sms"]])
      create_group(survey, channel)

      attrs = %{schedule_day_of_week: %{sun: false, mon: true, tue: true, wed: false, thu: false, fri: false, sat: false}}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)

      assert new_survey.state == "ready"
    end

    test "updates state when removing schedule", %{conn: conn, user: user} do
      [project, questionnaire, channel] = prepare_for_state_update(user)

      survey = insert(:survey, project: project, questionnaires: [questionnaire], cutoff: 3, schedule_day_of_week: completed_schedule)
      create_group(survey, channel)

      attrs = %{schedule_day_of_week: incomplete_schedule}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)

      assert new_survey.state == "not_ready"
    end

    test "updates state when removing questionnaire", %{conn: conn, user: user} do
      [project, questionnaire, channel] = prepare_for_state_update(user)

      survey = insert(:survey, project: project, questionnaires: [questionnaire], cutoff: 4, state: "ready", schedule_day_of_week: completed_schedule)
      create_group(survey, channel)

      assert survey.state == "ready"

      attrs = %{questionnaire_ids: []}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)

      qs = (new_survey |> Repo.preload(:questionnaires)).questionnaires
      assert length(qs) == 0

      assert new_survey.state == "not_ready"
    end

    test "does not update state when adding cutoff if missing questionnaire", %{conn: conn, user: user} do
      [project, _, channel] = prepare_for_state_update(user)

      survey = insert(:survey, project: project, schedule_day_of_week: completed_schedule)
      assert survey.state == "not_ready"

      create_group(survey, channel)

      attrs = %{cutoff: 4}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)

      assert new_survey.state == "not_ready"
    end

    test "does not update state when adding cutoff if missing respondents", %{conn: conn, user: user} do
      [project, questionnaire, _] = prepare_for_state_update(user)

      survey = insert(:survey, project: project, questionnaires: [questionnaire], schedule_day_of_week: completed_schedule)
      assert survey.state == "not_ready"

      attrs = %{cutoff: 4}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)

      assert new_survey.state == "not_ready"
    end

    test "does not update state when adding questionnaire if missing channel", %{conn: conn, user: user} do
      [project, questionnaire, _] = prepare_for_state_update(user)

      survey = insert(:survey, project: project, cutoff: 4, schedule_day_of_week: completed_schedule)
      group = insert(:respondent_group, survey: survey)
      add_respondent_to group

      attrs = %{questionnaire_id: questionnaire.id}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)

      assert new_survey.state == "not_ready"
    end

    test "sets to not ready if comparisons' ratio don't sum 100", %{conn: conn, user: user} do
      [project, questionnaire, channel] = prepare_for_state_update(user)

      survey = insert(:survey, project: project, questionnaires: [questionnaire], cutoff: 3, schedule_day_of_week: completed_schedule, mode: [["sms"]])
      create_group(survey, channel)

      attrs = %{comparisons: [%{questionnaire_id: questionnaire.id, mode: ["sms"], ratio: 99}]}

      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)

      assert new_survey.state == "not_ready"
    end

    test "sets to ready if comparisons' ratio sum 100", %{conn: conn, user: user} do
      [project, questionnaire, channel] = prepare_for_state_update(user)

      survey = insert(:survey, project: project, questionnaires: [questionnaire], cutoff: 3, schedule_day_of_week: completed_schedule, mode: [["sms"]])
      create_group(survey, channel)

      attrs = %{comparisons: [%{questionnaire_id: questionnaire.id, mode: ["sms"], ratio: 100}]}

      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)

      assert new_survey.state == "ready"
    end

    test "changes state to not_ready when questionnaire is invalid", %{conn: conn, user: user} do
      [project, questionnaire, channel] = prepare_for_state_update(user)

      survey = insert(:survey, project: project, cutoff: 4, schedule_day_of_week: completed_schedule, mode: [["sms"]], questionnaires: [])
      create_group(survey, channel)

      questionnaire |> Ask.Questionnaire.changeset(%{"valid" => false}) |> Repo.update!
      attrs = %{questionnaire_ids: [questionnaire.id]}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)

      assert new_survey.state == "not_ready"
    end

    test "changes state to not_ready when survey mode doesn't match questionnaire mode", %{conn: conn, user: user} do
      [project, questionnaire, channel] = prepare_for_state_update(user)
      questionnaire |> Ask.Questionnaire.changeset(%{"modes" => ["ivr"]}) |> Repo.update!

      survey = insert(:survey, project: project, cutoff: 4, schedule_day_of_week: completed_schedule, mode: [["ivr"]], questionnaires: [questionnaire])
      create_group(survey, channel)

      attrs = %{mode: [["sms"]]}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)

      assert new_survey.state == "not_ready"
    end
  end

  test "prevents launching a survey that is not in the ready state", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    survey = insert(:survey, project: project, state: "not_ready")
    conn = post conn, project_survey_survey_path(conn, :launch, survey.project, survey)
    assert response(conn, 422)
  end

  test "when launching a survey, it sets the state to running", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    survey = insert(:survey, project: project, state: "ready")
    conn = post conn, project_survey_survey_path(conn, :launch, survey.project, survey)
    assert json_response(conn, 200)
    assert Repo.get(Survey, survey.id).state == "running"
  end

  test "when launching a survey, it creates questionnaire snapshots", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    questionnaire = insert(:questionnaire, name: "test", project: project, steps: @dummy_steps)

    questionnaire |> Ask.Questionnaire.recreate_variables!

    survey = insert(:survey, project: project, state: "ready", questionnaires: [questionnaire], comparisons: [
        %{"mode" => ["sms"], "questionnaire_id" => questionnaire.id, "one" => 50},
        %{"mode" => ["sms"], "questionnaire_id" => questionnaire.id, "two" => 40},
      ])
    conn = post conn, project_survey_survey_path(conn, :launch, survey.project, survey)
    assert json_response(conn, 200)

    survey = Repo.get(Survey, survey.id)
    |> Repo.preload(:questionnaires)

    qs = survey.questionnaires
    assert length(qs) == 1

    q = hd(qs)
    assert q.snapshot_of == questionnaire.id
    assert q.name == questionnaire.name
    assert q.steps == questionnaire.steps
    assert q.modes == questionnaire.modes

    assert survey.comparisons == [
      %{"mode" => ["sms"], "questionnaire_id" => q.id, "one" => 50},
      %{"mode" => ["sms"], "questionnaire_id" => q.id, "two" => 40},
    ]
  end

  test "survey view contains questionnaire modes for each questionnaire after launching a survey", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    questionnaire = insert(:questionnaire, name: "test", project: project, steps: @dummy_steps, modes: ["sms", "ivr"])
    survey_ready = insert(:survey, project: project, state: "ready", questionnaires: [questionnaire])

    post conn, project_survey_survey_path(conn, :launch, survey_ready.project, survey_ready)
    survey_launched = Repo.get(Survey, survey_ready.id)

    conn = get conn, project_survey_path(conn, :show, project, survey_launched)
    questionnaire_snapshot_id = ((survey_launched |> Repo.preload(:questionnaires)).questionnaires |> hd).id |> Integer.to_string
    response = json_response(conn, 200)["data"]

    assert response["questionnaires"][questionnaire_snapshot_id]["modes"] == questionnaire.modes
  end

  test "forbids launch for project reader", %{conn: conn, user: user} do
    project = create_project_for_user(user, level: "reader")
    survey = insert(:survey, project: project, state: "ready")
    assert_error_sent :forbidden, fn ->
      post conn, project_survey_survey_path(conn, :launch, survey.project, survey)
    end
  end

  test "launches a survey with channel", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    survey = insert(:survey, project: project, state: "ready")

    test_channel = TestChannel.new
    channel = insert(:channel, settings: test_channel |> TestChannel.settings, type: "sms")
    create_group(survey, channel)

    conn = post conn, project_survey_survey_path(conn, :launch, survey.project, survey)
    assert json_response(conn, 200)
    assert Repo.get(Survey, survey.id).state == "running"

    assert_received [:prepare, ^test_channel, "http://app.ask.dev/callbacks/test"]
  end

  test "sets started_at with proper datetime value when a survey is launched", %{conn: conn, user: user} do
    now = Timex.now
    project = create_project_for_user(user)
    survey = insert(:survey, project: project, state: "ready")
    post conn, project_survey_survey_path(conn, :launch, survey.project, survey)
    started_at = Repo.get(Survey, survey.id).started_at
    assert (Timex.between?(started_at, Timex.shift(now, seconds: -3), Timex.shift(now, seconds: 3)))
  end

  test "updates project updated_at when a survey is launched", %{conn: conn, user: user}  do
    datetime = Ecto.DateTime.cast!("2000-01-01 00:00:00")
    project = create_project_for_user(user)
    survey = insert(:survey, project: project, state: "ready")
    post conn, project_survey_survey_path(conn, :launch, survey.project, survey)

    project = Project |> Repo.get(project.id)
    assert Ecto.DateTime.compare(project.updated_at, datetime) == :gt
  end

  test "stops survey", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    questionnaire = insert(:questionnaire, name: "test", project: project)
    survey = insert(:survey, project: project, state: "running")

    test_channel = TestChannel.new(false)
    channel = insert(:channel, settings: test_channel |> TestChannel.settings, type: "sms")
    group = create_group(survey, channel)

    insert_list(10, :respondent, survey: survey, state: "pending")
    r1 = insert(:respondent, survey: survey, state: "active", respondent_group: group)
    insert_list(3, :respondent, survey: survey, state: "stalled", timeout_at: Timex.now)

    channel_state = %{"call_id" => 123}
    session = %Session{
      current_mode: SessionModeProvider.new("sms", channel, []),
      channel_state: channel_state,
      respondent: r1,
      flow: %Flow{questionnaire: questionnaire},
    }
    session = Session.dump(session)
    r1 |> Ask.Respondent.changeset(%{session: session}) |> Repo.update!

    conn = post conn, project_survey_survey_path(conn, :stop, survey.project, survey)

    assert json_response(conn, 200)
    survey = Repo.get(Survey, survey.id)
    assert Survey.cancelled?(survey)

    assert length(Repo.all(from(r in Ask.Respondent, where: (r.state == "cancelled" and is_nil(r.session) and is_nil(r.timeout_at))))) == 4
    assert_receive [:cancel_message, ^test_channel, ^channel_state]
  end

  test "stops respondents only for the stopped survey", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    questionnaire = insert(:questionnaire, name: "test", project: project)
    survey  = insert(:survey, project: project, state: "running")
    survey2 = insert(:survey, project: project, state: "running")

    test_channel = TestChannel.new(false)
    channel = insert(:channel, settings: test_channel |> TestChannel.settings, type: "sms")
    group = create_group(survey, channel)

    r1 = insert(:respondent, survey: survey, state: "active", respondent_group: group)
    insert_list(3, :respondent, survey: survey, state: "stalled", respondent_group: group, timeout_at: Timex.now)
    insert_list(4, :respondent, survey: survey2, state: "active", session: %{})
    insert_list(2, :respondent, survey: survey2, state: "stalled", timeout_at: Timex.now)

    channel_state = %{"call_id" => 123}
    session = %Session{
      current_mode: SessionModeProvider.new("sms", channel, []),
      channel_state: channel_state,
      respondent: r1,
      flow: %Flow{questionnaire: questionnaire},
    }
    session = Session.dump(session)
    r1 |> Ask.Respondent.changeset(%{session: session}) |> Repo.update!

    conn = post conn, project_survey_survey_path(conn, :stop, survey.project, survey)

    assert json_response(conn, 200)
    assert Repo.get(Survey, survey2.id).state == "running"

    assert length(Repo.all(from(r in Ask.Respondent, where: (r.state == "active" or r.state == "stalled" )))) == 6
    assert_receive [:cancel_message, ^test_channel, ^channel_state]
  end

  test "stopping completed survey still works (#736)", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    survey = insert(:survey, project: project, state: "terminated", exit_code: 0, exit_message: "Successfully completed")

    conn = post conn, project_survey_survey_path(conn, :stop, survey.project, survey)

    assert json_response(conn, 200)
    survey = Repo.get(Survey, survey.id)
    assert Survey.completed?(survey)
  end

  test "stopping cancelled survey still works (#736)", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    survey = insert(:survey, project: project, state: "terminated", exit_code: 1)

    conn = post conn, project_survey_survey_path(conn, :stop, survey.project, survey)

    assert json_response(conn, 200)
    survey = Repo.get(Survey, survey.id)
    assert Survey.cancelled?(survey)
  end

  def prepare_for_state_update(user) do
    project = create_project_for_user(user)
    questionnaire = insert(:questionnaire, name: "test", project: project)
    channel = insert(:channel, name: "test")
    [project, questionnaire, channel]
  end

  defp add_respondent_to(group = %RespondentGroup{}) do
    insert(:respondent, phone_number: "12345678", survey: group.survey, respondent_group: group)
  end

  def completed_schedule do
    %Ask.DayOfWeek{sun: false, mon: true, tue: true, wed: false, thu: false, fri: false, sat: false}
  end

  def incomplete_schedule do
    %{sun: false, mon: false, tue: false, wed: false, thu: false, fri: false, sat: false}
  end

  defp add_channel_to(group = %RespondentGroup{}, channel = %Channel{}) do
    RespondentGroupChannel.changeset(%RespondentGroupChannel{}, %{respondent_group_id: group.id, channel_id: channel.id, mode: channel.type})
    |> Repo.insert
  end

  defp create_group(survey, channel \\ nil) do
    group = insert(:respondent_group, survey: survey, respondents_count: 1)
    if channel do
      add_channel_to(group, channel)
    end
    add_respondent_to group
    group
  end
end
