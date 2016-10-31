defmodule Ask.ProjectControllerTest do
  use Ask.ConnCase

  alias Ask.Project
  @valid_attrs %{name: "some content"}

  setup %{conn: conn} do
    user = insert(:user)
    conn = conn
      |> put_private(:test_user, user)
      |> put_req_header("accept", "application/json")
    {:ok, conn: conn, user: user}
  end

  describe "index" do

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
                          "name"    => user_project.name,
                          "updated_at" => Ecto.DateTime.to_iso8601(user_project.updated_at)}
      assert json_response(conn, 200)["data"] == [user_project_map]
    end

  end

  describe "show" do

    test "shows chosen resource", %{conn: conn, user: user} do
      project = insert(:project, user: user)
      conn = get conn, project_path(conn, :show, project)
      assert json_response(conn, 200)["data"] == %{"id" => project.id,
        "user_id" => project.user_id,
        "name" => project.name,
        "updated_at" => Ecto.DateTime.to_iso8601(project.updated_at)}
    end

    test "renders page not found when id is nonexistent", %{conn: conn} do
      assert_error_sent 404, fn ->
        get conn, project_path(conn, :show, -1)
      end
    end

    test "forbid access to projects from other users", %{conn: conn} do
      project = insert(:project)
      assert_error_sent :forbidden, fn ->
        get conn, project_path(conn, :show, project)
      end
    end

  end

  describe "create" do

    test "creates and renders resource when data is valid", %{conn: conn} do
      conn = post conn, project_path(conn, :create), project: @valid_attrs
      assert json_response(conn, 201)["data"]["id"]
      assert Repo.get_by(Project, @valid_attrs)
    end

  end

  describe "update" do

    test "updates and renders chosen resource when data is valid", %{conn: conn, user: user} do
      project = insert(:project, user: user)
      conn = put conn, project_path(conn, :update, project), project: @valid_attrs
      assert json_response(conn, 200)["data"]["id"]
      assert Repo.get_by(Project, @valid_attrs)
    end

    test "rejects update if the project doesn't belong to the current user", %{conn: conn} do
      project = insert(:project)
      assert_error_sent :forbidden, fn ->
        put conn, project_path(conn, :update, project), project: @valid_attrs
      end
    end

  end

  describe "delete" do

    test "deletes chosen resource", %{conn: conn, user: user} do
      project = insert(:project, user: user)
      conn = delete conn, project_path(conn, :delete, project)
      assert response(conn, 204)
      refute Repo.get(Project, project.id)
    end

    test "rejects delete if the project doesn't belong to the current user", %{conn: conn} do
      project = insert(:project)
      assert_error_sent :forbidden, fn ->
        delete conn, project_path(conn, :delete, project)
      end
    end

  end

end
