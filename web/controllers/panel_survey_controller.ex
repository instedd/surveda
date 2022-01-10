defmodule Ask.PanelSurveyController do
  use Ask.Web, :api_controller
  use Ask.Web, :append_assigns_to_action

  import Survey.Helper
  alias Ask.{PanelSurvey, Repo}

  plug :assign_project when action in [:index, :show]
  plug :assign_project_for_change when action in [:create, :update, :delete, :new_wave]

  def index(conn, _params, %{project: project}) do
    panel_surveys = Repo.all(from p in PanelSurvey,
      where: p.project_id == ^project.id and is_nil(p.folder_id))

    render(conn, "index.json", panel_surveys: panel_surveys)
  end

  def create(conn, %{"survey_id" => survey_id}, %{project: project}) do
    survey = load_survey(project, survey_id)

    with {:ok, %PanelSurvey{} = panel_survey} <- Ask.Runtime.PanelSurvey.create_panel_survey_from_survey(survey) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", project_panel_survey_path(conn, :show, project.id, panel_survey))
      |> render("show.json", panel_survey: panel_survey)
    end
  end

  def show(conn, %{"id" => id}, %{project: project}) do
    panel_survey = load_panel_survey(project, id)
    |> Repo.preload(:waves)
    |> Repo.preload(:folder)

    render(conn, "show.json", panel_survey: panel_survey)
  end

  def update(conn, %{"id" => id, "panel_survey" => panel_survey_params}, %{project: project}) do
    panel_survey = load_panel_survey(project, id)

    with {:ok, %PanelSurvey{} = panel_survey} <- PanelSurvey.update_panel_survey(panel_survey, panel_survey_params) do
      render(conn, "show.json", panel_survey: panel_survey)
    end
  end

  def delete(conn, %{"id" => id}, %{project: project}) do
    panel_survey = load_panel_survey(project, id)

    with {:ok, %PanelSurvey{}} <- PanelSurvey.delete_panel_survey(panel_survey) do
      send_resp(conn, :no_content, "")
    end
  end

  def new_wave(conn, %{"panel_survey_id" => id}, %{project: project}) do
    panel_survey = load_panel_survey(project, id)

    with {:ok, %{new_wave: _new_wave}} <- Ask.Runtime.PanelSurvey.new_wave(panel_survey) do
      # Reload the panel survey. One of its surveys has changed, so it's outdated
      panel_survey = Repo.get!(PanelSurvey, id)
      render(conn, "show.json", panel_survey: panel_survey)
    end
  end

  defp load_panel_survey(project, id) do
    project
    |> assoc(:panel_surveys)
    |> Repo.get!(id)
  end
end
