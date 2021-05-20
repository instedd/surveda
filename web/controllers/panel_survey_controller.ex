defmodule Ask.PanelSurveyController do
  use Ask.Web, :api_controller

  alias Ask.{PanelSurvey, Repo}

  def index(conn, _params) do
    panel_surveys = PanelSurvey.list_panel_surveys()
    render(conn, "index.json", panel_surveys: panel_surveys)
  end

  def create(conn, %{"project_id" => project_id, "panel_survey" => panel_survey_params}) do
    project = conn
    |> load_project_for_change(project_id)

    panel_survey_params = Map.put(panel_survey_params, "project_id", project.id)

    with {:ok, %PanelSurvey{} = panel_survey} <- PanelSurvey.create_panel_survey(panel_survey_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", project_panel_survey_path(conn, :show, project.id, panel_survey))
      |> render("show.json", panel_survey: panel_survey)
    end
  end

  def show(conn, %{"project_id" => project_id, "id" => id}) do
    project = conn
    |> load_project_for_change(project_id)

    panel_survey = project
      |> assoc(:panel_surveys)
      |> Repo.get!(id)

    render(conn, "show.json", panel_survey: panel_survey)
  end

  # def show(conn, %{"project_id" => project_id, "id" => id}) do
  #   latest_panel_survey =
  #     load_project(conn, project_id)
  #     |> assoc(:surveys)
  #     |> where([s], s.panel_survey_of == ^id and s.latest_panel_survey)
  #     |> Repo.one!()

  #   panel_survey = prepare_panel_survey(latest_panel_survey)

  #   render(conn, "show.json", panel_survey: panel_survey)
  # end

  # defp prepare_panel_survey(
  #        %{
  #          panel_survey_of: panel_survey_of,
  #          name: name,
  #          folder_id: folder_id,
  #          id: id,
  #          project_id: project_id
  #        } = _latest_panel_survey
  #      ) do
  #   %{
  #     id: panel_survey_of,
  #     name: name,
  #     folder_id: folder_id,
  #     latest_survey_id: id,
  #     project_id: project_id
  #   }
  # end
end
