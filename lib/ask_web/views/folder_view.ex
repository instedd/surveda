defmodule AskWeb.FolderView do
  use AskWeb, :view

  def render("index.json", %{folders: folders}) do
    %{data: render_many(folders, AskWeb.FolderView, "folder.json")}
  end

  def render("show.json", %{folder: folder}) do
    %{data: render_one(folder, AskWeb.FolderView, "folder.json")}
  end

  def render("folder.json", %{
        folder:
          %{
            panel_surveys: panel_surveys,
            surveys: surveys
          } = folder
      }) do
    %{
      id: folder.id,
      name: folder.name,
      project_id: folder.project_id
    }
    |> put_if(Ecto.assoc_loaded?(panel_surveys), :panel_surveys, fn ->
      render_many(panel_surveys, AskWeb.PanelSurveyView, "panel_survey.json")
    end)
    |> put_if(Ecto.assoc_loaded?(surveys), :surveys, fn ->
      render_many(surveys, AskWeb.SurveyView, "survey.json")
    end)
  end

  defp put_if(map, condition, key, callback) do
    if condition do
      Map.put(map, key, callback.())
    else
      map
    end
  end
end
