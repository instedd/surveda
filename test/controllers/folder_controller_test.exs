defmodule Ask.FolderControllerTest do
  use Ask.ConnCase
  use Ask.DummySteps
  use Ask.TestHelpers

  alias Ask.{Folder}
  @valid_attrs %{name: "some content"}

  setup %{conn: conn} do
    user = insert(:user)
    conn = conn
      |> put_private(:test_user, user)
      |> put_req_header("accept", "application/json")
    {:ok, conn: conn, user: user}
  end

  describe "show" do

    test "shows chosen resource", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      folder = insert(:folder, project_id: project.id)
      folder = Folder |> Repo.get(folder.id)
      conn = get conn, project_folder_path(conn, :show, project.id, folder.id)
      assert json_response(conn, 200)["data"] == %{
        "id" => folder.id,
        "name" => folder.name,
        "project_id" => folder.project_id
      }
    end

    test "renders page not found when id is nonexistent", %{conn: conn, user: user} do
      project = create_project_for_user(user)

      assert_error_sent 404, fn ->
        get conn, project_folder_path(conn, :show, project.id, -1)
      end
    end

  end

  describe "create" do

    test "creates and renders resource when data is valid", %{conn: conn, user: user} do
      project = create_project_for_user(user)

      conn = post conn, project_folder_path(conn, :create, project.id), folder: Map.merge(@valid_attrs, %{project_id: project.id})
      response = json_response(conn, 201)
      assert response["data"]["id"]
      assert Repo.get_by(Folder, @valid_attrs)
    end

  end

  describe "delete:" do
    test "deletes chosen resource", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      folder1 = insert(:folder, project: project)
      folder2 = insert(:folder, project: project)

      assert Repo.get(Folder, folder1.id)
      assert Repo.get(Folder, folder2.id)

      conn = delete conn, project_folder_path(conn, :delete, project, folder1)
      assert response(conn, 204)

      refute Repo.get(Folder, folder1.id)
      assert Repo.get(Folder, folder2.id)
    end

    test "rejects delete if the project doesn't belong to the current user", %{conn: conn} do
      project = insert(:project)
      folder = insert(:folder, project: project)
      assert_error_sent :forbidden, fn ->
        delete conn, project_folder_path(conn, :delete, project, folder)
      end
    end

    test "rejects delete if the folder has surveys", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      folder = insert(:folder, project: project)
      insert(:survey, project: project, folder_id: folder.id)

      assert_error_sent :bad_request, fn ->
        delete conn, project_folder_path(conn, :delete, project, folder)
      end

      assert Repo.get(Folder, folder.id)
    end

  end

end
