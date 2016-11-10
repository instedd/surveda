defmodule Ask.SurveyControllerTest do
  use Ask.ConnCase

  alias Ask.{Survey, Project}
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
      project = insert(:project, user: user)
      conn = get conn, project_survey_path(conn, :index, project.id)
      assert json_response(conn, 200)["data"] == []
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
      project = insert(:project, user: user)
      survey = insert(:survey, project: project)
      conn = get conn, project_survey_path(conn, :show, project, survey)
      assert json_response(conn, 200)["data"] == %{"id" => survey.id,
        "name" => survey.name,
        "mode" => survey.mode,
        "project_id" => survey.project_id,
        "questionnaire_id" => nil,
        "channels" => [],
        "cutoff" => nil,
        "state" => "not_ready",
        "respondents_count" => 0,
        "schedule_day_of_week" => %{
          "fri" => false, "mon" => false, "sat" => false, "sun" => false, "thu" => false, "tue" => false, "wed" => false
        },
        "schedule_start_time" => nil,
        "schedule_end_time" => nil,
        "timezone" => "UTC",
        "started_at" => nil
      }
    end

    test "shows chosen resource with channels", %{conn: conn, user: user} do
      project = insert(:project, user: user)
      channel = insert(:channel, user: user)
      survey = insert(:survey, project: project)
      insert(:survey_channel, survey_id: survey.id, channel_id: channel.id )
      conn = get conn, project_survey_path(conn, :show, project, survey)
      assert json_response(conn, 200)["data"] == %{"id" => survey.id,
        "name" => survey.name,
        "mode" => survey.mode,
        "project_id" => survey.project_id,
        "questionnaire_id" => nil,
        "channels" => [%{
          "id" => channel.id,
          "type" => "sms"
        }],
        "cutoff" => nil,
        "state" => "not_ready",
        "respondents_count" => 0,
        "schedule_day_of_week" => %{
          "fri" => false, "mon" => false, "sat" => false, "sun" => false, "thu" => false, "tue" => false, "wed" => false
        },
        "schedule_start_time" => nil,
        "schedule_end_time" => nil,
        "timezone" => "UTC",
        "started_at" => nil
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
      project = insert(:project, user: user)
      conn = post conn, project_survey_path(conn, :create, project.id)
      assert json_response(conn, 201)["data"]["id"]
      assert Repo.get_by(Survey, %{project_id: project.id})
    end

    # test "does not create resource and renders errors when data is invalid", %{conn: conn, user: user} do
    #   project = insert(:project, user: user)
    #   conn = post conn, project_survey_path(conn, :create, project.id), survey: @invalid_attrs
    #   assert json_response(conn, 422)["errors"] != %{}
    # end

    test "forbids creation of survey for a project that belongs to another user", %{conn: conn} do
      project = insert(:project)
      assert_error_sent :forbidden, fn ->
        post conn, project_survey_path(conn, :create, project.id), survey: @valid_attrs
      end
    end

    test "updates project updated_at when survey is created", %{conn: conn, user: user}  do
      datetime = Ecto.DateTime.cast!("2000-01-01 00:00:00")
      project = insert(:project, user: user, updated_at: datetime)
      post conn, project_survey_path(conn, :create, project.id)

      project = Project |> Repo.get(project.id)
      assert Ecto.DateTime.compare(project.updated_at, datetime) == :gt
    end
  end

  describe "update" do
    test "updates and renders chosen resource when data is valid", %{conn: conn, user: user} do
      project = insert(:project, user: user)
      survey = insert(:survey, project: project, schedule_start_time: Ecto.Time.cast!("09:00:00"), schedule_end_time: Ecto.Time.cast!("18:00:00"))
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: @valid_attrs
      assert json_response(conn, 200)["data"]["id"]
      assert Repo.get_by(Survey, @valid_attrs)
    end

    test "updates schedule when data is valid", %{conn: conn, user: user} do
      [project, questionnaire, _] = prepare_for_state_update(user)

      survey = insert(:survey, project: project, questionnaire_id: questionnaire.id, schedule_start_time: Ecto.Time.cast!("09:00:00"), schedule_end_time: Ecto.Time.cast!("18:00:00"))

      attrs = %{schedule_day_of_week: %{sun: true, mon: true, tue: true, wed: true, thu: true, fri: false, sat: true}}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["schedule_day_of_week"]["sun"] == true
    end

    test "updates cutoff when channels are included in params", %{conn: conn, user: user} do
      [project, questionnaire, channel] = prepare_for_state_update(user)

      survey = insert(:survey, project: project, questionnaire_id: questionnaire.id, schedule_start_time: Ecto.Time.cast!("09:00:00"), schedule_end_time: Ecto.Time.cast!("18:00:00"))
      add_channel_to(survey, channel)
      add_respondent_to survey

      attrs = %{cutoff: 4, channels: [channel.id]}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["cutoff"] == 4
    end

    test "does not update chosen resource and renders errors when data is invalid", %{conn: conn, user: user} do
      project = insert(:project, user: user)
      survey = insert(:survey, project: project)
      conn = put conn, project_survey_path(conn, :update, survey.project, survey), survey: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end

    test "deletes previous channels associations when updates including channels params", %{conn: conn, user: user} do
      channel = insert(:channel, user: user)
      channel2 = insert(:channel, user: user)
      project = insert(:project, user: user)
      survey = insert(:survey, project: project, schedule_start_time: Ecto.Time.cast!("09:00:00"), schedule_end_time: Ecto.Time.cast!("18:00:00"))
      insert(:survey_channel, survey_id: survey.id, channel_id: channel.id )
      conn = put conn, project_survey_path(conn, :update, survey.project, survey), survey: %{channels: [channel2.id]}

      assert json_response(conn, 200)["data"] == %{
        "id" => survey.id,
        "mode" => survey.mode,
        "name" => survey.name,
        "project_id" => survey.project_id,
        "questionnaire_id" => nil,
        "channels" => [%{
           "id" => channel2.id,
           "type" => "sms"
        }],
        "cutoff" => nil,
        "state" => "not_ready",
        "respondents_count" => 0,
        "schedule_day_of_week" => %{
          "fri" => false, "mon" => false, "sat" => false, "sun" => false, "thu" => false, "tue" => false, "wed" => false
        },
        "schedule_start_time" => "09:00:00",
        "schedule_end_time" => "18:00:00",
        "timezone" => "UTC",
        "started_at" => nil
      }
    end

    test "rejects update if the survey doesn't belong to the current user", %{conn: conn} do
      survey = insert(:survey)
      assert_error_sent :forbidden, fn ->
        put conn, project_survey_path(conn, :update, survey.project, survey), survey: @invalid_attrs
      end
    end

    test "fails if the schedule from is greater or equal to the to", %{conn: conn, user: user} do
      project = insert(:project, user: user)
      survey = insert(:survey, project: project)
      attrs = Map.merge(@valid_attrs, %{schedule_start_time: "02:00:00", schedule_end_time: "01:00:00"})
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 422)["errors"] != %{}
    end

    test "schedule to and from are saved successfully", %{conn: conn, user: user} do
      project = insert(:project, user: user)
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
      project = insert(:project, user: user)
      survey = insert(:survey, project: project)
      max_int = 2147483648
      attrs = Map.merge(@valid_attrs, %{cutoff: max_int})
      conn = put conn, project_survey_path(conn, :update, survey.project, survey), survey: attrs
      assert json_response(conn, 422)["errors"] != %{cutoff: "must be less than #{max_int}"}
    end

    test "rejects update with correct error when cutoff field is less than zero", %{conn: conn, user: user} do
      project = insert(:project, user: user)
      survey = insert(:survey, project: project)
      attrs = Map.merge(@valid_attrs, %{cutoff: 0})
      conn = put conn, project_survey_path(conn, :update, survey.project, survey), survey: attrs
      assert json_response(conn, 422)["errors"] != %{cutoff: "must be greater than 0"}
    end

    test "updates project updated_at when survey is updated", %{conn: conn, user: user}  do
      datetime = Ecto.DateTime.cast!("2000-01-01 00:00:00")
      project = insert(:project, user: user, updated_at: datetime, )
      survey = insert(:survey, project: project, schedule_start_time: Ecto.Time.cast!("09:00:00"), schedule_end_time: Ecto.Time.cast!("18:00:00"))
      put conn, project_survey_path(conn, :update, survey.project, survey), survey: %{name: "New name"}

      project = Project |> Repo.get(project.id)
      assert Ecto.DateTime.compare(project.updated_at, datetime) == :gt
    end
  end

  describe "delete" do
    test "deletes chosen resource", %{conn: conn, user: user} do
      project = insert(:project, user: user)
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

    test "updates project updated_at when survey is deleted", %{conn: conn, user: user}  do
      datetime = Ecto.DateTime.cast!("2000-01-01 00:00:00")
      project = insert(:project, user: user, updated_at: datetime)
      survey = insert(:survey, project: project)
      delete conn, project_survey_path(conn, :delete, survey.project, survey)

      project = Project |> Repo.get(project.id)
      assert Ecto.DateTime.compare(project.updated_at, datetime) == :gt
    end
  end

  describe "changes the survey state when needed" do
    test "updates state when adding questionnaire", %{conn: conn, user: user} do
      [project, questionnaire, channel] = prepare_for_state_update(user)

      survey = insert(:survey, project: project, cutoff: 4, schedule_day_of_week: completed_schedule, schedule_start_time: Ecto.Time.cast!("09:00:00"), schedule_end_time: Ecto.Time.cast!("18:00:00"), mode: ["sms"])
      add_channel_to(survey, channel)
      add_respondent_to survey

      attrs = %{questionnaire_id: questionnaire.id}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)

      assert new_survey.state == "ready"
    end

    test "updates state when selecting mode", %{conn: conn, user: user} do
      [project, questionnaire, channel] = prepare_for_state_update(user)

      survey = insert(:survey, project: project, questionnaire_id: questionnaire.id, cutoff: 4, schedule_day_of_week: completed_schedule, schedule_start_time: Ecto.Time.cast!("09:00:00"), schedule_end_time: Ecto.Time.cast!("18:00:00"))
      add_channel_to(survey, channel)
      add_respondent_to survey

      attrs = %{mode: ["sms"]}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)

      assert new_survey.state == "ready"
    end

    test "updates state when selecting mode, missing channel", %{conn: conn, user: user} do
      [project, questionnaire, channel] = prepare_for_state_update(user)

      survey = insert(:survey, project: project, questionnaire_id: questionnaire.id, cutoff: 4, schedule_day_of_week: completed_schedule, schedule_start_time: Ecto.Time.cast!("09:00:00"), schedule_end_time: Ecto.Time.cast!("18:00:00"))
      add_channel_to(survey, channel)
      add_respondent_to survey

      attrs = %{mode: ["sms", "ivr"]}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)

      assert new_survey.state == "not_ready"
    end

    test "updates state when selecting mode, all channels", %{conn: conn, user: user} do
      [project, questionnaire, channel] = prepare_for_state_update(user)

      survey = insert(:survey, project: project, questionnaire_id: questionnaire.id, cutoff: 4, schedule_day_of_week: completed_schedule, schedule_start_time: Ecto.Time.cast!("09:00:00"), schedule_end_time: Ecto.Time.cast!("18:00:00"))
      add_respondent_to survey

      channel2 = insert(:channel, user: user, type: "ivr")

      survey
      |> Repo.preload([:channels])
      |> Ecto.Changeset.change
      |> put_assoc(:channels, [channel, channel2])
      |> Repo.update

      attrs = %{mode: ["sms", "ivr"]}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)

      assert new_survey.state == "ready"
    end

    test "updates state when adding cutoff", %{conn: conn, user: user} do
      [project, questionnaire, channel] = prepare_for_state_update(user)

      survey = insert(:survey, project: project, questionnaire_id: questionnaire.id, schedule_day_of_week: completed_schedule, schedule_start_time: Ecto.Time.cast!("09:00:00"), schedule_end_time: Ecto.Time.cast!("18:00:00"), mode: ["sms"])
      add_channel_to(survey, channel)
      add_respondent_to survey

      attrs = %{cutoff: 4}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)

      assert new_survey.state == "ready"
    end

    test "updates state when adding channel", %{conn: conn, user: user} do
      [project, questionnaire, channel] = prepare_for_state_update(user)

      survey = insert(:survey, project: project, questionnaire_id: questionnaire.id, cutoff: 3, schedule_day_of_week: completed_schedule, schedule_start_time: Ecto.Time.cast!("09:00:00"), schedule_end_time: Ecto.Time.cast!("18:00:00"), mode: ["sms"])
      add_channel_to(survey, channel)
      add_respondent_to survey

      attrs = %{channels: [channel.id]}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)

      assert new_survey.state == "ready"
    end

    test "updates state when adding a day in schedule", %{conn: conn, user: user} do
      [project, questionnaire, channel] = prepare_for_state_update(user)

      survey = insert(:survey, project: project, questionnaire_id: questionnaire.id, cutoff: 3, schedule_start_time: Ecto.Time.cast!("09:00:00"), schedule_end_time: Ecto.Time.cast!("18:00:00"), mode: ["sms"])
      add_channel_to(survey, channel)
      add_respondent_to survey

      attrs = %{schedule_day_of_week: %{sun: false, mon: true, tue: true, wed: false, thu: false, fri: false, sat: false}}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)

      assert new_survey.state == "ready"
    end

    test "updates state when removing schedule", %{conn: conn, user: user} do
      [project, questionnaire, channel] = prepare_for_state_update(user)

      survey = insert(:survey, project: project, questionnaire_id: questionnaire.id, cutoff: 3, schedule_day_of_week: completed_schedule, schedule_start_time: Ecto.Time.cast!("09:00:00"), schedule_end_time: Ecto.Time.cast!("18:00:00"))
      add_channel_to(survey, channel)
      add_respondent_to survey

      attrs = %{schedule_day_of_week: incomplete_schedule}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)

      assert new_survey.state == "not_ready"
    end

    test "updates state when removing channel", %{conn: conn, user: user} do
      [project, questionnaire, channel] = prepare_for_state_update(user)

      survey = insert(:survey, project: project, questionnaire_id: questionnaire.id, cutoff: 4, state: "ready", schedule_day_of_week: completed_schedule, schedule_start_time: Ecto.Time.cast!("09:00:00"), schedule_end_time: Ecto.Time.cast!("18:00:00"))
      add_respondent_to survey
      add_channel_to(survey, channel)

      assert survey.state == "ready"

      attrs = %{channels: []}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)

      assert new_survey.state == "not_ready"
    end

    test "updates state when removing questionnaire", %{conn: conn, user: user} do
      [project, questionnaire, channel] = prepare_for_state_update(user)

      survey = insert(:survey, project: project, questionnaire_id: questionnaire.id, cutoff: 4, state: "ready", schedule_day_of_week: completed_schedule, schedule_start_time: Ecto.Time.cast!("09:00:00"), schedule_end_time: Ecto.Time.cast!("18:00:00"))
      add_respondent_to survey
      add_channel_to(survey, channel)

      assert survey.state == "ready"

      attrs = %{questionnaire_id: nil}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)

      assert new_survey.state == "not_ready"
    end

    test "does not update state when adding cutoff if missing questionnaire", %{conn: conn, user: user} do
      [project, _, channel] = prepare_for_state_update(user)

      survey = insert(:survey, project: project, schedule_day_of_week: completed_schedule, schedule_start_time: Ecto.Time.cast!("09:00:00"), schedule_end_time: Ecto.Time.cast!("18:00:00"))
      assert survey.state == "not_ready"
      add_channel_to(survey, channel)
      add_respondent_to survey

      attrs = %{cutoff: 4}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)

      assert new_survey.state == "not_ready"
    end

    test "does not update state when adding cutoff if missing respondents", %{conn: conn, user: user} do
      [project, questionnaire, channel] = prepare_for_state_update(user)

      survey = insert(:survey, project: project, questionnaire_id: questionnaire.id, schedule_day_of_week: completed_schedule, schedule_start_time: Ecto.Time.cast!("09:00:00"), schedule_end_time: Ecto.Time.cast!("18:00:00"))
      assert survey.state == "not_ready"
      add_channel_to(survey, channel)

      attrs = %{cutoff: 4}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)

      assert new_survey.state == "not_ready"
    end

    test "does not update state when adding questionnaire if missing channel", %{conn: conn, user: user} do
      [project, questionnaire, _] = prepare_for_state_update(user)

      survey = insert(:survey, project: project, cutoff: 4, schedule_day_of_week: completed_schedule, schedule_start_time: Ecto.Time.cast!("09:00:00"), schedule_end_time: Ecto.Time.cast!("18:00:00"))
      add_respondent_to survey

      attrs = %{questionnaire_id: questionnaire.id}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)

      assert new_survey.state == "not_ready"
    end
  end

  test "launch survey", %{conn: conn, user: user} do
    project = insert(:project, user: user)
    survey = insert(:survey, schedule_start_time: Ecto.Time.cast!("09:00:00"), schedule_end_time: Ecto.Time.cast!("18:00:00"), project: project)
    conn = post conn, project_survey_survey_path(conn, :launch, survey.project, survey)
    assert json_response(conn, 200)
    assert Repo.get(Survey, survey.id).state == "running"
  end

  test "updates project updated_at when survey is launched", %{conn: conn, user: user}  do
    datetime = Ecto.DateTime.cast!("2000-01-01 00:00:00")
    project = insert(:project, user: user, updated_at: datetime)
    survey = insert(:survey, project: project, schedule_start_time: Ecto.Time.cast!("09:00:00"), schedule_end_time: Ecto.Time.cast!("18:00:00"))
    post conn, project_survey_survey_path(conn, :launch, survey.project, survey)

    project = Project |> Repo.get(project.id)
    assert Ecto.DateTime.compare(project.updated_at, datetime) == :gt
  end

  ### Auxiliar functions ###

  def prepare_for_state_update(user) do
    project = insert(:project, user: user)
    questionnaire = insert(:questionnaire, name: "test", project: project)
    channel = insert(:channel, name: "test")
    [project, questionnaire, channel]
  end

  def add_respondent_to(survey) do
    insert(:respondent, phone_number: "12345678", survey: survey)
  end

  def completed_schedule do
    %Ask.DayOfWeek{sun: false, mon: true, tue: true, wed: false, thu: false, fri: false, sat: false}
  end

  def incomplete_schedule do
    %{sun: false, mon: false, tue: false, wed: false, thu: false, fri: false, sat: false}
  end

  def add_channel_to(survey, channel) do
    channels_changeset = Repo.get!(Ask.Channel, channel.id) |> change

    changeset = survey
    |> Repo.preload([:channels])
    |> Ecto.Changeset.change
    |> put_assoc(:channels, [channels_changeset])

    Repo.update(changeset)
  end
end
