defmodule AskWeb.PanelSurveyController do
  use AskWeb, :api_controller

  alias Ask.{
    ActivityLog,
    Folder,
    PanelSurvey,
    Repo
  }

  alias Ecto.Multi

  def index(conn, %{"project_id" => project_id}) do
    project =
      conn
      |> load_project(project_id)

    panel_surveys =
      Repo.all(
        from p in PanelSurvey,
          where: p.project_id == ^project.id and is_nil(p.folder_id)
      )

    render(conn, "index.json", panel_surveys: panel_surveys)
  end

  def create(conn, %{"project_id" => project_id, "survey_id" => survey_id}) do
    project =
      conn
      |> load_project_for_change(project_id)

    survey =
      project
      |> assoc(:surveys)
      |> Repo.get!(survey_id)

    with {:ok, %PanelSurvey{} = panel_survey} <-
           Ask.Runtime.PanelSurvey.create_panel_survey_from_survey(survey) do
      conn
      |> put_status(:created)
      |> put_resp_header(
        "location",
        project_panel_survey_path(conn, :show, project.id, panel_survey)
      )
      |> render("show.json", panel_survey: panel_survey)
    end
  end

  def show(conn, %{"project_id" => project_id, "id" => id}) do
    project =
      conn
      |> load_project(project_id)

    panel_survey =
      project
      |> assoc(:panel_surveys)
      |> Repo.get!(id)
      |> Repo.preload(:waves)
      |> Repo.preload(:folder)

    render(conn, "show.json", panel_survey: panel_survey)
  end

  def update(conn, %{
        "project_id" => project_id,
        "id" => id,
        "panel_survey" => panel_survey_params
      }) do
    project =
      conn
      |> load_project_for_change(project_id)

    panel_survey =
      project
      |> assoc(:panel_surveys)
      |> Repo.get!(id)

    with {:ok, %PanelSurvey{} = panel_survey} <-
           PanelSurvey.update_panel_survey(panel_survey, panel_survey_params) do
      render(conn, "show.json", panel_survey: panel_survey)
    end
  end

  def delete(conn, %{"project_id" => project_id, "id" => id}) do
    project =
      conn
      |> load_project_for_change(project_id)

    panel_survey =
      project
      |> assoc(:panel_surveys)
      |> Repo.get!(id)

    with {:ok, %PanelSurvey{}} <- PanelSurvey.delete_panel_survey(panel_survey) do
      send_resp(conn, :no_content, "")
    end
  end

  def new_wave(conn, %{"project_id" => project_id, "panel_survey_id" => id}) do
    project =
      conn
      |> load_project_for_change(project_id)

    panel_survey =
      project
      |> assoc(:panel_surveys)
      |> Repo.get!(id)

    with {:ok, %{new_wave: _new_wave}} <- Ask.Runtime.PanelSurvey.new_wave(panel_survey) do
      # Reload the panel survey. One of its surveys has changed, so it's outdated
      panel_survey = Repo.get!(PanelSurvey, id)
      render(conn, "show.json", panel_survey: panel_survey)
    end
  end

  def set_folder_id(conn, %{
        "project_id" => project_id,
        "panel_survey_id" => id,
        "folder_id" => folder_id
      }) do
    project =
      conn
      |> load_project_for_change(project_id)

    panel_survey =
      project
      |> assoc(:panel_surveys)
      |> Repo.get!(id)

    old_folder_name =
      if panel_survey.folder_id,
        do: Repo.get(Folder, panel_survey.folder_id).name,
        else: "No Folder"

    new_folder_name =
      if folder_id,
        do: (project |> assoc(:folders) |> Repo.get!(folder_id)).name,
        else: "No Folder"

    result =
      Multi.new()
      |> Multi.update(
        :set_folder_id,
        PanelSurvey.changeset(panel_survey, %{folder_id: folder_id})
      )
      |> Multi.insert(
        :change_folder_log,
        ActivityLog.panel_survey_change_folder(
          project,
          conn,
          panel_survey,
          old_folder_name,
          new_folder_name
        )
      )
      |> Repo.transaction()

    case result do
      {:ok, _} ->
        send_resp(conn, :no_content, "")

      {:error, _, changeset, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(AskWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end
