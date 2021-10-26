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

    data =
      if panel_survey.folder_id && Ecto.assoc_loaded?(panel_survey.folder) do
        Map.put(data, :folder, %{
          id: panel_survey.folder.id,
          project_id: panel_survey.folder.project_id,
          name: panel_survey.folder.name
        })
      else
        data
      end

    if Ecto.assoc_loaded?(occurrences) do
      Map.put(data, :occurrences, render_many(occurrences, Ask.SurveyView, "survey.json"))
    else
      data
    end
  end
end
