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
      "channels" => []}
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
        "channel_id" => channel.id,
        "type" => "sms"
      }]
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

  test "deletes chosen resource", %{conn: conn} do
    survey = insert(:survey)
    conn = delete conn, project_survey_path(conn, :delete, survey.project, survey)
    assert response(conn, 204)
    refute Repo.get(Survey, survey.id)
  end
end
