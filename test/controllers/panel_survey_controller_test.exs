defmodule AskWeb.PanelSurveyControllerTest do
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
      project = create_project_for_user(user)
      panel_survey = insert(:panel_survey, project: project)

      conn = get(conn, project_panel_survey_path(conn, :index, project.id))

      assert_listed_panel_survey(conn, panel_survey)
    end
  end

  defp assert_listed_panel_survey(conn, base) do
    body = json_response(conn, 200)
    data = body["data"]
    assert data
    listed_panel_survey = Enum.at(data, 0)

    assert listed_panel_survey == %{
             "folder_id" => base.folder_id,
             "id" => base.id,
             "name" => base.name,
             "project_id" => base.project_id
           }
  end
end
