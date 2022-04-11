defmodule AskWeb.PanelSurveyView do
  use AskWeb, :view

  def render("index.json", %{panel_surveys: panel_surveys}) do
    %{data: render_many(panel_surveys, AskWeb.PanelSurveyView, "panel_survey.json")}
  end

  def render("show.json", %{panel_survey: panel_survey}) do
    %{data: render_one(panel_survey, AskWeb.PanelSurveyView, "panel_survey.json")}
  end

  def render("panel_survey.json", %{
        panel_survey:
          %{
            folder_id: folder_id,
            id: id,
            project_id: project_id,
            name: name,
            waves: waves
          } = panel_survey
      }) do
    data = %{
      folder_id: folder_id,
      id: id,
      name: name,
      project_id: project_id,
      updated_at: Ask.PanelSurvey.updated_at(panel_survey),
      latest_wave:
        render_one(Ask.PanelSurvey.latest_wave(panel_survey), AskWeb.SurveyView, "survey.json"),
      is_repeatable: Ask.PanelSurvey.repeatable?(panel_survey)
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

    if Ecto.assoc_loaded?(waves) do
      Map.put(data, :waves, render_many(waves, AskWeb.SurveyView, "survey.json"))
    else
      data
    end
  end
end
