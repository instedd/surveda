defmodule Ask.PanelSurveyView do
  use Ask.Web, :view
  alias Ask.PanelSurveyView

  def render("index.json", %{panel_surveys: panel_surveys}) do
    %{data: render_many(panel_surveys, PanelSurveyView, "panel_survey.json")}
  end

  def render("show.json", %{panel_survey: panel_survey}) do
    %{data: render_one(panel_survey, Ask.PanelSurveyView, "panel_survey.json")}
  end

  def render("panel_survey.json", %{
        panel_survey: %{
          folder_id: folder_id,
          id: id,
          project_id: project_id,
          name: name
        }
      }) do
    %{
      folder_id: folder_id,
      id: id,
      name: name,
      project_id: project_id
    }
  end
end
