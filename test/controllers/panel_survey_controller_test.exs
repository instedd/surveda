defmodule Ask.PanelSurveyControllerTest do
  use Ask.ConnCase
  use Ask.TestHelpers
  alias Ask.PanelSurvey

  setup %{conn: conn} do
    user = insert(:user)

    conn =
      conn
      |> put_private(:test_user, user)
      |> put_req_header("accept", "application/json")

    {:ok, conn: conn, user: user}
  end

  describe "index" do
    test "lists a panel_survey", %{conn: conn, user: user} do
      panel_survey = panel_survey(user)

      conn = get(conn, project_panel_survey_path(conn, :index, panel_survey.project_id))

      assert_listed_panel_survey(conn, panel_survey)
    end

    test "lists a panel_survey inside a folder", %{conn: conn, user: user} do
      panel_survey = panel_survey_inside_folder(user)

      conn = get(conn, project_panel_survey_path(conn, :index, panel_survey.project_id))

      assert_listed_panel_survey(conn, panel_survey)
    end
  end

  describe "show" do
    test "shows a panel survey", %{conn: conn, user: user} do
      panel_survey = panel_survey(user)

      conn =
        get(
          conn,
          project_panel_survey_path(conn, :show, panel_survey.project_id, panel_survey.id)
        )

      assert_showed_panel_survey(conn, panel_survey)
    end

    test "shows a panel survey inside a folder", %{conn: conn, user: user} do
      panel_survey = panel_survey_inside_folder(user)

      conn =
        get(
          conn,
          project_panel_survey_path(conn, :show, panel_survey.project_id, panel_survey.id)
        )

      assert_showed_panel_survey(conn, panel_survey)
    end
  end

  describe "create" do
    test "creates panel survey", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      name = @foo_string

      conn =
        post(conn, project_panel_survey_path(conn, :create, project.id),
          panel_survey: %{name: name}
        )

      assert_created_panel_survey(conn, %{name: name, project_id: project.id, folder_id: nil})
    end

    test "creates panel survey inside a folder", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      folder = insert(:folder, project: project)
      name = @foo_string

      conn =
        post(conn, project_panel_survey_path(conn, :create, project.id),
          panel_survey: %{name: name, folder_id: folder.id}
        )

      assert_created_panel_survey(conn, %{
        name: name,
        project_id: project.id,
        folder_id: folder.id
      })
    end
  end

  describe "delete" do
    test "deletes chosen panel_survey", %{conn: conn, user: user} do
      panel_survey = panel_survey(user)

      conn = delete conn, project_panel_survey_path(conn, :delete, panel_survey.project_id, panel_survey.id)

      assert_deleted_panel_survey(conn, panel_survey.id)
    end

    test "deletes chosen panel_survey inside a folder", %{conn: conn, user: user} do
      panel_survey = panel_survey_inside_folder(user)

      conn = delete conn, project_panel_survey_path(conn, :delete, panel_survey.project_id, panel_survey.id)

      assert_deleted_panel_survey(conn, panel_survey.id)
    end
  end

  defp panel_survey_inside_folder(user) do
    panel_survey(user, true)
  end

  defp panel_survey(user, inside_folder \\ false) do
    project = create_project_for_user(user)
    folder = if inside_folder, do: insert(:folder, project: project), else: nil
    insert(:panel_survey, project: project, folder: folder)
  end

  defp assert_deleted_panel_survey(conn, panel_survey_id) do
    assert response(conn, 204) == ""
    assert Repo.get(PanelSurvey, panel_survey_id) == nil
  end

  defp assert_created_panel_survey(conn, %{
         project_id: project_id,
         name: name,
         folder_id: folder_id
       }) do
    body = json_response(conn, 201)
    data = body["data"]
    assert data
    id = data["id"]
    assert id
    created_panel_survey = Repo.get!(PanelSurvey, id)

    assert created_panel_survey.project_id == project_id
    assert created_panel_survey.name == name
    assert created_panel_survey.folder_id == folder_id
  end

  defp assert_showed_panel_survey(conn, base) do
    body = json_response(conn, 200)
    showed_panel_survey = body["data"]

    assert assert_panel_survey(showed_panel_survey, base)
  end

  defp assert_listed_panel_survey(conn, base) do
    body = json_response(conn, 200)
    data = body["data"]
    assert data
    listed_panel_survey = Enum.at(data, 0)

    assert assert_panel_survey(listed_panel_survey, base)
  end

  defp assert_panel_survey(panel_survey, base) do
    assert panel_survey == %{
             "folder_id" => base.folder_id,
             "id" => base.id,
             "name" => base.name,
             "project_id" => base.project_id
           }
  end
end
