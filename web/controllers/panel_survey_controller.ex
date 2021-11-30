defmodule Ask.PanelSurveyController do
  use Ask.Web, :api_controller
  alias Ask.{PanelSurvey, Repo}

  def index(conn, %{"project_id" => project_id}) do
    project = conn
    |> load_project(project_id)

    panel_surveys = Repo.all(from p in PanelSurvey,
      where: p.project_id == ^project.id and is_nil(p.folder_id))

    render(conn, "index.json", panel_surveys: panel_surveys)
  end

  def create(conn, %{"project_id" => project_id, "survey_id" => survey_id}) do
    project = conn
      |> load_project_for_change(project_id)

    survey = project
      |> assoc(:surveys)
      |> Repo.get!(survey_id)

    with {:ok, %PanelSurvey{} = panel_survey} <- Ask.Runtime.PanelSurvey.create_panel_survey_from_survey(survey) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", project_panel_survey_path(conn, :show, project.id, panel_survey))
      |> render("show.json", panel_survey: panel_survey)
    end
  end

  def show(conn, %{"project_id" => project_id, "id" => id}) do
    project = conn
    |> load_project(project_id)

    panel_survey = project
    |> assoc(:panel_surveys)
    |> Repo.get!(id)
    |> Repo.preload(:waves)
    |> Repo.preload(:folder)

    render(conn, "show.json", panel_survey: panel_survey)
  end

  def update(conn, %{"project_id" => project_id, "id" => id, "panel_survey" => panel_survey_params}) do
    project = conn
    |> load_project_for_change(project_id)

    panel_survey = project
      |> assoc(:panel_surveys)
      |> Repo.get!(id)

    with {:ok, %PanelSurvey{} = panel_survey} <- PanelSurvey.update_panel_survey(panel_survey, panel_survey_params) do
      render(conn, "show.json", panel_survey: panel_survey)
    end
  end

  def delete(conn, %{"project_id" => project_id, "id" => id}) do
    project = conn
    |> load_project_for_change(project_id)

    panel_survey = project
      |> assoc(:panel_surveys)
      |> Repo.get!(id)

    with {:ok, %PanelSurvey{}} <- PanelSurvey.delete_panel_survey(panel_survey) do
      send_resp(conn, :no_content, "")
    end
  end

  def new_wave(conn, %{"project_id" => project_id, "panel_survey_id" => id}) do
    project = conn
    |> load_project_for_change(project_id)

    panel_survey = project
      |> assoc(:panel_surveys)
      |> Repo.get!(id)

    with {:ok, %{new_wave: _new_wave}} <- Ask.Runtime.PanelSurvey.new_wave(panel_survey) do
      # Reload the panel survey. One of its surveys has changed, so it's outdated
      panel_survey = Repo.get!(PanelSurvey, id)
      render(conn, "show.json", panel_survey: panel_survey)
    end
  end
end
