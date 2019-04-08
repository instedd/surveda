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

end
