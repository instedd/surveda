defmodule Ask.QuestionnaireControllerTest do
  use Ask.ConnCase

  alias Ask.Project
  alias Ask.Questionnaire
  @valid_attrs %{name: "some content"}
  @invalid_attrs %{}

  setup %{conn: conn} do
    user = insert(:user)
    conn = conn
      |> put_private(:test_user, user)
      |> put_req_header("accept", "application/json")
    {:ok, conn: conn, user: user}
  end

  test "denies access without login token" do
    conn = build_conn()
    conn = get conn, project_questionnaire_path(conn, :index, -1)
    assert json_response(conn, :unauthorized)["error"] == "Unauthorized"
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, project_questionnaire_path(conn, :index, -1)
    assert json_response(conn, 200)["data"] == []
  end

  test "shows chosen resource", %{conn: conn} do
    questionnaire = insert(:questionnaire)
    conn = get conn, project_questionnaire_path(conn, :show, questionnaire.project, questionnaire)
    assert json_response(conn, 200)["data"] == %{"id" => questionnaire.id,
      "name" => questionnaire.name,
      "project_id" => questionnaire.project_id}
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, project_questionnaire_path(conn, :show, -1, -1)
    end
  end

  test "creates and renders resource when data is valid", %{conn: conn} do
    project = Repo.insert! %Project{}
    conn = post conn, project_questionnaire_path(conn, :create, project.id), questionnaire: @valid_attrs
    assert json_response(conn, 201)["data"]["id"]
    assert Repo.get_by(Questionnaire, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    project = Repo.insert! %Project{}
    conn = post conn, project_questionnaire_path(conn, :create, project.id), questionnaire: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  # test "updates and renders chosen resource when data is valid", %{conn: conn} do
  #   questionnaire = Repo.insert! %Questionnaire{}
  #   conn = put conn, questionnaire_path(conn, :update, questionnaire), questionnaire: @valid_attrs
  #   assert json_response(conn, 200)["data"]["id"]
  #   assert Repo.get_by(Questionnaire, @valid_attrs)
  # end

  # test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
  #   questionnaire = Repo.insert! %Questionnaire{}
  #   conn = put conn, questionnaire_path(conn, :update, questionnaire), questionnaire: @invalid_attrs
  #   assert json_response(conn, 422)["errors"] != %{}
  # end

  # test "deletes chosen resource", %{conn: conn} do
  #   questionnaire = Repo.insert! %Questionnaire{}
  #   conn = delete conn, questionnaire_path(conn, :delete, questionnaire)
  #   assert response(conn, 204)
  #   refute Repo.get(Questionnaire, questionnaire.id)
  # end
end
