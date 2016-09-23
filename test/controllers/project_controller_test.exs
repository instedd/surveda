defmodule Ask.ProjectControllerTest do
  use Ask.ConnCase

  alias Ask.Project
  @valid_attrs %{name: "some content"}
  @invalid_attrs %{name: ""}

  setup %{conn: conn} do
    user = insert(:user)
    conn = conn
      |> put_private(:test_user, user)
      |> put_req_header("accept", "application/json")
    {:ok, conn: conn, user: user}
  end

  test "returns code 200 and empty list if there are no entries", %{conn: conn} do
    conn = get conn, project_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
  end

  test "list only entries of the current user on index", %{conn: conn, user: user} do
    user_project = insert(:project, user: user)
    insert(:project)

    conn = get conn, project_path(conn, :index)
    user_project_map = %{"id"      => user_project.id,
                         "user_id" => user_project.user_id,
                         "name"    => user_project.name}
    assert json_response(conn, 200)["data"] == [user_project_map]
  end

  test "shows chosen resource", %{conn: conn, user: user} do
    project = insert(:project, user: user)
    conn = get conn, project_path(conn, :show, project)
    assert json_response(conn, 200)["data"] == %{"id" => project.id,
      "user_id" => project.user_id,
      "name" => project.name}
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, project_path(conn, :show, -1)
    end
  end

  test "rejects show if the project doesn't belong to the current user", %{conn: conn} do
    project = insert(:project)
    conn = get conn, project_path(conn, :show, project)
    assert conn.status == 403
  end

  test "creates and renders resource when data is valid", %{conn: conn} do
    conn = post conn, project_path(conn, :create), project: @valid_attrs
    assert json_response(conn, 201)["data"]["id"]
    assert Repo.get_by(Project, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, project_path(conn, :create), project: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates and renders chosen resource when data is valid", %{conn: conn, user: user} do
    project = insert(:project, user: user)
    conn = put conn, project_path(conn, :update, project), project: @valid_attrs
    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(Project, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn, user: user} do
    project = insert(:project, user: user)
    conn = put conn, project_path(conn, :update, project), project: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "rejects update if the project doesn't belong to the current user", %{conn: conn} do
    project = insert(:project)
    conn = put conn, project_path(conn, :update, project), project: @valid_attrs
    assert conn.status == 403
  end

  test "deletes chosen resource", %{conn: conn, user: user} do
    project = insert(:project, user: user)
    conn = delete conn, project_path(conn, :delete, project)
    assert response(conn, 204)
    refute Repo.get(Project, project.id)
  end

  test "rejects delete if the project doesn't belong to the current user", %{conn: conn} do
    project = insert(:project)
    conn = delete conn, project_path(conn, :delete, project)
    assert conn.status == 403
  end

end
