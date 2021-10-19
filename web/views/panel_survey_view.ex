defmodule Ask.PanelSurveyView do
  use Ask.Web, :view
  alias Ask.{PanelSurveyView,PanelSurvey}

  def render("index.json", %{panel_surveys: panel_surveys}) do
    %{data: render_many(panel_surveys, PanelSurveyView, "panel_survey.json")}
  end

  def render("show.json", %{panel_survey: panel_survey}) do
    %{data: render_one(panel_survey, PanelSurveyView, "panel_survey.json")}
  end

  def render("panel_survey.json", %{
    panel_survey: %{
      folder_id: folder_id,
      id: id,
      project_id: project_id,
      name: name,
      occurrences: occurrences
    } = panel_survey
  }) do
    data = %{
      folder_id: folder_id,
      id: id,
      name: name,
      project_id: project_id,
      updated_at: PanelSurvey.updated_at(panel_survey),
      latest_occurrence: render_one(PanelSurvey.latest_occurrence(panel_survey), Ask.SurveyView, "survey.json"),
      is_repeatable: PanelSurvey.repeatable?(panel_survey)
    }

    if Ecto.assoc_loaded?(occurrences) do
      Map.put(data, :occurrences, render_many(occurrences, Ask.SurveyView, "survey.json"))
    else
      data
    end
  end
end
