defmodule Ask.PanelSurveyView do
  use Ask.Web, :view
  alias Ask.{PanelSurveyView,PanelSurvey}
  alias Ask.Repo

  def render("index.json", %{panel_surveys: panel_surveys}) do
    %{data: render_many(panel_surveys, PanelSurveyView, "panel_survey.json")}
  end

  def render("show.json", %{panel_survey: panel_survey}) do
    %{data: render_one(panel_survey, Ask.PanelSurveyView, "panel_survey.json")}
  end

  def render("panel_survey.json", %{
        panel_survey:
          %{
            folder_id: folder_id,
            id: id,
            project_id: project_id,
            name: name
          } = panel_survey
      }) do
    # if there ins't any occurrence (empty panel survey, which is forbidden) the UI will crash
    occurrences = Repo.preload(panel_survey, :occurrences).occurrences

    %{
      folder_id: folder_id,
      id: id,
      name: name,
      project_id: project_id,
      updated_at: PanelSurvey.updated_at(panel_survey),
      occurrences: render_many(occurrences, Ask.SurveyView, "survey.json")
    }
  end
end
