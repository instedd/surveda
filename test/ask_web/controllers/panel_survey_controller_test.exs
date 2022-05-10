defmodule AskWeb.PanelSurveyControllerTest do
  use AskWeb.ConnCase
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

    test "won't list a panel_survey inside a folder", %{conn: conn, user: user} do
      panel_survey = panel_survey_in_folder(user)

      conn = get(conn, project_panel_survey_path(conn, :index, panel_survey.project_id))

      assert json_response(conn, 200)["data"] == []
    end
  end

  # Here we're testing the `panel_survey_in_folder` function, which is a ad-hoc function
  # for these tests. It may be not so pure, but... it doesn't hurt, right?
  describe "panel_survey/1 and panel_survey_in_folder/1" do
    test "creates a panel survey with no folder", %{user: user} do
      panel_survey = panel_survey(user)

      refute panel_survey.folder_id
    end

    test "creates a panel survey inside a folder", %{user: user} do
      panel_survey = panel_survey_in_folder(user)

      assert panel_survey.folder_id
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
      project = create_project_for_user(user)
      folder = insert(:folder, project: project)
      panel_survey = insert(:panel_survey, project: project, folder: folder)
      insert(:survey, project: project, panel_survey: panel_survey)

      conn =
        get(
          conn,
          project_panel_survey_path(conn, :show, project.id, panel_survey.id)
        )

      assert_showed_panel_survey(conn, panel_survey)

      assert json_response(conn, 200)["data"]["folder"] == %{
               "id" => folder.id,
               "project_id" => project.id,
               "name" => folder.name
             }
    end

    test "shows a panel survey with surveys", %{conn: conn, user: user} do
      panel_survey = panel_survey_with_surveys(user)

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

      survey =
        insert(:survey,
          project: project,
          generates_panel_survey: true,
          state: :ready,
          name: @foo_string
        )

      conn =
        post(conn, project_panel_survey_path(conn, :create, project.id), survey_id: survey.id)

      assert_created_panel_survey(conn, %{
        name: survey.name,
        project_id: project.id,
        folder_id: nil
      })
    end

    test "creates panel survey inside a folder", %{conn: conn, user: user} do
      project = create_project_for_user(user)
      folder = insert(:folder, project: project)

      survey =
        insert(:survey,
          project: project,
          generates_panel_survey: true,
          folder: folder,
          state: :ready,
          name: @foo_string
        )

      conn =
        post(conn, project_panel_survey_path(conn, :create, project.id), survey_id: survey.id)

      assert_created_panel_survey(conn, %{
        name: survey.name,
        project_id: project.id,
        folder_id: folder.id
      })
    end
  end

  describe "update panel_survey" do
    test "updates a panel survey", %{conn: conn, user: user} do
      panel_survey = panel_survey(user) |> Repo.preload(:project)
      folder = insert(:folder, project: panel_survey.project)
      name = @bar_string

      conn =
        put(
          conn,
          project_panel_survey_path(conn, :update, panel_survey.project_id, panel_survey.id),
          panel_survey: %{name: name, folder_id: folder.id}
        )

      assert_updated_panel_survey(conn, %{
        name: name,
        project_id: panel_survey.project_id,
        folder_id: folder.id
      })
    end
  end

  describe "delete" do
    test "deletes chosen panel_survey", %{conn: conn, user: user} do
      panel_survey = panel_survey(user)

      conn =
        delete(
          conn,
          project_panel_survey_path(conn, :delete, panel_survey.project_id, panel_survey.id)
        )

      assert_deleted_panel_survey(conn, panel_survey.id)
    end

    test "deletes chosen panel_survey inside a folder", %{conn: conn, user: user} do
      panel_survey = panel_survey_in_folder(user)

      conn =
        delete(
          conn,
          project_panel_survey_path(conn, :delete, panel_survey.project_id, panel_survey.id)
        )

      assert_deleted_panel_survey(conn, panel_survey.id)
    end
  end

  describe "new_wave" do
    test "creates a new wave", %{conn: conn, user: user} do
      panel_survey = panel_survey_with_last_wave_terminated(user)
      previous_wave = PanelSurvey.latest_wave(panel_survey)

      conn =
        post(
          conn,
          project_panel_survey_panel_survey_path(
            conn,
            :new_wave,
            panel_survey.project_id,
            panel_survey.id
          )
        )

      response_panel_survey = json_response(conn, 200)["data"]
      panel_survey = Repo.get!(PanelSurvey, panel_survey.id)
      assert_new_wave(response_panel_survey, previous_wave, panel_survey)
    end
  end

  defp assert_new_wave(response_panel_survey, previous_wave, panel_survey) do
    new_wave = PanelSurvey.latest_wave(panel_survey)
    assert new_wave.id > previous_wave.id
    assert new_wave.state == :ready
    assert assert_panel_survey(response_panel_survey, panel_survey)
  end

  defp panel_survey_with_last_wave_terminated(user) do
    panel_survey_with_surveys(user)
    |> complete_last_wave_of_panel_survey()
  end

  defp panel_survey_with_surveys(user) do
    panel_survey = panel_survey(user) |> Repo.preload(:project)
    insert(:survey, project: panel_survey.project, panel_survey: panel_survey)
    Repo.get!(PanelSurvey, panel_survey.id) |> Repo.preload(:waves)
  end

  defp panel_survey_in_folder(user) do
    panel_survey(user, true)
  end

  defp panel_survey(user, inside_folder \\ false) do
    project = create_project_for_user(user)

    if inside_folder do
      dummy_panel_survey_in_folder(project)
    else
      dummy_panel_survey(project)
    end
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
    assert_panel_survey_action(conn, %{
      project_id: project_id,
      name: name,
      folder_id: folder_id,
      code: 201
    })
  end

  defp assert_updated_panel_survey(conn, %{
         project_id: project_id,
         name: name,
         folder_id: folder_id
       }) do
    assert_panel_survey_action(conn, %{
      project_id: project_id,
      name: name,
      folder_id: folder_id,
      code: 200
    })
  end

  defp assert_panel_survey_action(conn, %{
         project_id: project_id,
         name: name,
         folder_id: folder_id,
         code: code
       }) do
    body = json_response(conn, code)
    data = body["data"]
    assert data
    id = data["id"]
    assert id
    created_panel_survey = Repo.get!(PanelSurvey, id)

    assert created_panel_survey.project_id == project_id
    assert created_panel_survey.name == name
    assert created_panel_survey.folder_id == folder_id
  end

  defp assert_showed_panel_survey(conn, base_panel_survey) do
    body = json_response(conn, 200)
    showed_panel_survey = body["data"]

    assert assert_panel_survey(showed_panel_survey, base_panel_survey)
  end

  defp assert_listed_panel_survey(conn, base_panel_survey) do
    body = json_response(conn, 200)
    data = body["data"]
    assert data
    listed_panel_survey = Enum.at(data, 0)

    assert assert_panel_survey(listed_panel_survey, base_panel_survey)
  end

  defp assert_panel_survey(panel_survey, base_panel_survey) do
    # It's easier to compare with the base panel without surveys.
    panel_survey_without_surveys =
      panel_survey
      |> Map.delete("waves")
      |> Map.delete("latest_wave")
      |> Map.delete("folder")

    assert panel_survey_without_surveys == %{
             "folder_id" => base_panel_survey.folder_id,
             "id" => base_panel_survey.id,
             "name" => base_panel_survey.name,
             "project_id" => base_panel_survey.project_id,
             "updated_at" => to_iso8601(PanelSurvey.updated_at(base_panel_survey)),
             "is_repeatable" => PanelSurvey.repeatable?(base_panel_survey)
           }

    # And then, it's also easier to compare only the surveys ids.
    assert panel_survey["latest_wave"]["id"] == PanelSurvey.latest_wave(base_panel_survey).id

    if Map.has_key?(panel_survey, "waves") do
      base_panel_survey = Repo.preload(base_panel_survey, :waves)
      assert survey_ids(panel_survey["waves"]) == survey_ids(base_panel_survey.waves)
    else
      true
    end
  end

  defp survey_ids(surveys) do
    Enum.map(surveys, fn survey -> survey_id(survey) end)
  end

  defp survey_id(%{"id" => id} = _survey), do: id

  defp survey_id(%{id: id} = _survey), do: id
end
