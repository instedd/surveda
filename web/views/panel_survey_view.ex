defmodule Ask.PanelSurveyView do
  use Ask.Web, :view

  def render("index.json", %{panel_surveys: panel_surveys}) do
    %{data: render_many(panel_surveys, Ask.PanelSurveyView, "panel_survey.json")}
  end

  def render("show.json", %{panel_survey: panel_survey}) do
    %{data: render_one(panel_survey, Ask.PanelSurveyView, "panel_survey.json")}
  end

  def render("panel_survey.json", %{
        panel_survey: %{
          folder_id: folder_id,
          id: id,
          is_repeatable: is_repeatable,
          latest_panel_survey_id: latest_panel_survey_id,
          name: name,
          project_id: project_id
        }
      }) do
    %{
      folder_id: folder_id,
      id: id,
      is_repeatable: is_repeatable,
      latest_panel_survey_id: latest_panel_survey_id,
      name: name,
      project_id: project_id
    }
  end
end
