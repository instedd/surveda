defmodule Ask.SurveyControllerTest do
  use Ask.ConnCase

  alias Ask.Survey
  @valid_attrs %{name: "some content"}
  @invalid_attrs %{name: ""}

  setup %{conn: conn} do
    user = insert(:user)
    conn = conn
      |> put_private(:test_user, user)
      |> put_req_header("accept", "application/json")
    {:ok, conn: conn, user: user}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, project_survey_path(conn, :index, -1)
    assert json_response(conn, 200)["data"] == []
  end

  test "shows chosen resource", %{conn: conn} do
    survey = insert(:survey)
    conn = get conn, project_survey_path(conn, :show, -1, survey)
    assert json_response(conn, 200)["data"] == %{"id" => survey.id,
      "name" => survey.name,
      "project_id" => survey.project_id,
      "questionnaire_id" => nil,
      "channels" => [],
      "cutoff" => nil,
      "state" => "not_ready",
      "respondents_count" => 0}
  end

  test "shows chosen resource with channels", %{conn: conn} do
    channel = insert(:channel)
    survey = insert(:survey)
    insert(:survey_channel, survey_id: survey.id, channel_id: channel.id )
    conn = get conn, project_survey_path(conn, :show, -1, survey)
    assert json_response(conn, 200)["data"] == %{"id" => survey.id,
      "name" => survey.name,
      "project_id" => survey.project_id,
      "questionnaire_id" => nil,
      "channels" => [%{
        "id" => channel.id,
        "type" => "sms"
      }],
      "cutoff" => nil,
      "state" => "not_ready",
      "respondents_count" => 0
    }
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, project_survey_path(conn, :show, -1, -1)
    end
  end

  test "creates and renders resource when data is valid", %{conn: conn} do
    project = insert(:project)
    conn = post conn, project_survey_path(conn, :create, project.id)
    assert json_response(conn, 201)["data"]["id"]
    assert Repo.get_by(Survey, %{project_id: project.id})
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, project_survey_path(conn, :create, 0)
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates and renders chosen resource when data is valid", %{conn: conn} do
    project = insert(:project)
    survey = insert(:survey, project: project)
    conn = put conn, project_survey_path(conn, :update, project, survey), survey: @valid_attrs
    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(Survey, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    survey = insert(:survey)
    conn = put conn, project_survey_path(conn, :update, survey.project, survey), survey: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes previous channels associations when updates including channels params", %{conn: conn} do
    channel = insert(:channel)
    channel2 = insert(:channel)
    survey = insert(:survey)
    insert(:survey_channel, survey_id: survey.id, channel_id: channel.id )
    conn = put conn, project_survey_path(conn, :update, survey.project, survey), survey: %{channels: [channel2.id]}

    assert json_response(conn, 200)["data"] == %{"id" => survey.id,
      "name" => survey.name,
      "project_id" => survey.project_id,
      "questionnaire_id" => nil,
      "channels" => [%{
        "id" => channel2.id,
        "type" => "sms"
      }],
      "cutoff" => nil,
      "state" => "not_ready",
      "respondents_count" => 0
    }
  end

  describe "changes the survey state when needed" do

    def prepare_for_state_update() do
      project = insert(:project)
      questionnaire = insert(:questionnaire, name: "test", project: project)
      channel = insert(:channel, name: "test")
      [project, questionnaire, channel]
    end

    def add_respondent_to(survey) do
      insert(:respondent, phone_number: "12345678", survey: survey)
    end

    def add_channel_to(survey, channel) do
      channels_changeset = Repo.get!(Ask.Channel, channel.id) |> change

      changeset = survey
      |> Repo.preload([:channels])
      |> Ecto.Changeset.change
      |> put_assoc(:channels, [channels_changeset])

      Repo.update(changeset)
    end

    test "updates state when adding questionnaire", %{conn: conn} do
      [project, questionnaire, channel] = prepare_for_state_update()

      survey = insert(:survey, project: project, cutoff: 4)
      add_channel_to(survey, channel)
      add_respondent_to survey

      attrs = %{questionnaire_id: questionnaire.id}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)

      assert new_survey.state == "ready"
    end

    test "updates state when adding cutoff", %{conn: conn} do
      [project, questionnaire, channel] = prepare_for_state_update()

      survey = insert(:survey, project: project, questionnaire_id: questionnaire.id)
      add_channel_to(survey, channel)
      add_respondent_to survey

      attrs = %{cutoff: 4}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)

      assert new_survey.state == "ready"
    end

    test "updates state when adding channel", %{conn: conn} do
      [project, questionnaire, channel] = prepare_for_state_update()

      survey = insert(:survey, project: project, questionnaire_id: questionnaire.id, cutoff: 3)
      add_channel_to(survey, channel)
      add_respondent_to survey

      attrs = %{channels: [channel.id]}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)

      assert new_survey.state == "ready"
    end

    test "updates state when removing channel", %{conn: conn} do
      [project, questionnaire, channel] = prepare_for_state_update()

      survey = insert(:survey, project: project, questionnaire_id: questionnaire.id, cutoff: 4, state: "ready")
      add_respondent_to survey
      add_channel_to(survey, channel)

      assert survey.state == "ready"

      attrs = %{channels: []}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)

      assert new_survey.state == "not_ready"
    end

    test "updates state when removing cutoff", %{conn: conn} do
      [project, questionnaire, channel] = prepare_for_state_update()

      survey = insert(:survey, project: project, questionnaire_id: questionnaire.id, cutoff: 4, state: "ready")
      add_respondent_to survey
      add_channel_to(survey, channel)

      assert survey.state == "ready"

      attrs = %{cutoff: nil}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)

      assert new_survey.state == "not_ready"
    end

    test "updates state when removing questionnaire", %{conn: conn} do
      [project, questionnaire, channel] = prepare_for_state_update()

      survey = insert(:survey, project: project, questionnaire_id: questionnaire.id, cutoff: 4, state: "ready")
      add_respondent_to survey
      add_channel_to(survey, channel)

      assert survey.state == "ready"

      attrs = %{questionnaire_id: nil}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)

      assert new_survey.state == "not_ready"
    end

    test "updates cutoff when channels are included in params", %{conn: conn} do
      [project, questionnaire, channel] = prepare_for_state_update()

      survey = insert(:survey, project: project, questionnaire_id: questionnaire.id)
      add_channel_to(survey, channel)
      add_respondent_to survey

      attrs = %{cutoff: 4, channels: [channel.id]}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["cutoff"] == 4
    end

    test "does not update state when adding cutoff if missing questionnaire", %{conn: conn} do
      [project, _, channel] = prepare_for_state_update()

      survey = insert(:survey, project: project)
      assert survey.state == "not_ready"
      add_channel_to(survey, channel)
      add_respondent_to survey

      attrs = %{cutoff: 4}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)

      assert new_survey.state == "not_ready"
    end

    test "does not update state when adding cutoff if missing respondents", %{conn: conn} do
      [project, questionnaire, channel] = prepare_for_state_update()

      survey = insert(:survey, project: project, questionnaire_id: questionnaire.id)
      assert survey.state == "not_ready"
      add_channel_to(survey, channel)

      attrs = %{cutoff: 4}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)

      assert new_survey.state == "not_ready"
    end

    test "does not update state when adding questionnaire if missing cutoff", %{conn: conn} do
      [project, questionnaire, channel] = prepare_for_state_update()

      survey = insert(:survey, project: project)
      assert survey.state == "not_ready"
      add_channel_to(survey, channel)
      add_respondent_to survey

      attrs = %{questionnaire_id: questionnaire.id}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)

      assert new_survey.state == "not_ready"
    end

    test "does not update state when adding questionnaire if missing channel", %{conn: conn} do
      [project, questionnaire, _] = prepare_for_state_update()

      survey = insert(:survey, project: project, cutoff: 4)
      add_respondent_to survey

      attrs = %{questionnaire_id: questionnaire.id}
      conn = put conn, project_survey_path(conn, :update, project, survey), survey: attrs
      assert json_response(conn, 200)["data"]["id"]
      new_survey = Repo.get(Survey, survey.id)

      assert new_survey.state == "not_ready"
    end
  end

  test "deletes chosen resource", %{conn: conn} do
    survey = insert(:survey)
    conn = delete conn, project_survey_path(conn, :delete, survey.project, survey)
    assert response(conn, 204)
    refute Repo.get(Survey, survey.id)
  end

  test "launch survey", %{conn: conn} do
    survey = insert(:survey)
    conn = post conn, project_survey_survey_path(conn, :launch, survey.project, survey)
    assert json_response(conn, 200)
    assert Repo.get(Survey, survey.id).state == "running"
  end
end
