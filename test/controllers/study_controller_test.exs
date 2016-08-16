defmodule Ask.StudyControllerTest do
  use Ask.ConnCase

  alias Ask.Study
  @valid_attrs %{name: "some content"}
  @invalid_attrs %{}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, study_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
  end

  test "shows chosen resource", %{conn: conn} do
    study = Repo.insert! %Study{}
    conn = get conn, study_path(conn, :show, study)
    assert json_response(conn, 200)["data"] == %{"id" => study.id,
      "user_id" => study.user_id,
      "name" => study.name}
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, study_path(conn, :show, -1)
    end
  end

  test "creates and renders resource when data is valid", %{conn: conn} do
    conn = post conn, study_path(conn, :create), study: @valid_attrs
    assert json_response(conn, 201)["data"]["id"]
    assert Repo.get_by(Study, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, study_path(conn, :create), study: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates and renders chosen resource when data is valid", %{conn: conn} do
    study = Repo.insert! %Study{}
    conn = put conn, study_path(conn, :update, study), study: @valid_attrs
    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(Study, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    study = Repo.insert! %Study{}
    conn = put conn, study_path(conn, :update, study), study: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes chosen resource", %{conn: conn} do
    study = Repo.insert! %Study{}
    conn = delete conn, study_path(conn, :delete, study)
    assert response(conn, 204)
    refute Repo.get(Study, study.id)
  end
end
