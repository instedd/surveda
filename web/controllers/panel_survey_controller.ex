defmodule Ask.PanelSurveyController do
  use Ask.Web, :api_controller

  alias Ask.{Repo, Survey}

  def index(conn, %{"project_id" => project_id}) do
    latest_panel_surveys =
      load_project(conn, project_id)
      |> assoc(:surveys)
      |> where([s], s.latest_panel_survey)
      |> Repo.all()

    panel_surveys = Enum.map(latest_panel_surveys, fn s -> prepare_panel_survey(s) end)

    render(conn, "index.json", panel_surveys: panel_surveys)
  end

  def show(conn, %{"project_id" => project_id, "id" => id}) do
    latest_panel_survey =
      load_project(conn, project_id)
      |> assoc(:surveys)
      |> where([s], s.panel_survey_of == ^id and s.latest_panel_survey)
      |> Repo.one!()

    panel_survey = prepare_panel_survey(latest_panel_survey)

    render(conn, "show.json", panel_survey: panel_survey)
  end

  defp prepare_panel_survey(
         %{
           panel_survey_of: panel_survey_of,
           name: name,
           folder_id: folder_id,
           id: id,
           project_id: project_id
         } = latest_panel_survey
       ) do
    %{
      id: panel_survey_of,
      name: name,
      folder_id: folder_id,
      is_repeatable: Survey.repeatable?(latest_panel_survey),
      latest_panel_survey_id: id,
      project_id: project_id
    }
  end
end
