defmodule Ask.RespondentControllerTest do
  use Ask.ConnCase

  @valid_attrs %{phone_number: "some content"}
  @invalid_attrs %{}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "lists all entries on index", %{conn: conn} do
    project = insert(:project)
    survey = insert(:survey, project: project)
    conn = get conn, project_survey_respondent_path(conn, :index, project.id, survey.id)
    assert json_response(conn, 200)["data"] == []
  end

  # test "creates and renders resource when data is valid", %{conn: conn} do
  #   project = insert(:project)
  #   survey = insert(:survey, project: project)
  #   conn = post conn, project_survey_respondent_path(conn, :create, project.id, survey.id), respondent: @valid_attrs
  #   assert json_response(conn, 201)["data"]["id"]
  #   assert Repo.get_by(Respondent, @valid_attrs)
  # end

  # test "does not create resource and renders errors when data is invalid", %{conn: conn} do
  #   conn = post conn, project_survey_respondent_path(conn, :create), respondent: @invalid_attrs
  #   assert json_response(conn, 422)["errors"] != %{}
  # end
end
