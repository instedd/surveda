defmodule Ask.ProjectView do
  use Ask.Web, :view

  def render("index.json", %{projects: projects, running_surveys_by_project: running_surveys_by_project, editors_by_project: editors_by_project}) do
    rendered = projects |> Enum.map(fn(project) ->
      one = render_one(project)
      one
      |> Map.put(:running_surveys, Map.get(running_surveys_by_project, project.id, 0))
      |> Map.put(:read_only, !Map.get(editors_by_project, project.id, false))
    end)
    %{data: rendered}
  end

  def render("show.json", %{project: project, read_only: read_only}) do
    rendered = render_one(project, Ask.ProjectView, "project.json")
    |> Map.put(:read_only, read_only)
    %{data: rendered}
  end

  def render("project.json", %{project: project}) do
    render_one(project)
  end

  def render("collaborators.json", %{collaborators: collaborators}) do
    %{data: %{collaborators: render_many(collaborators, Ask.ProjectView, "collaborator.json", as: :collaborator)}}
  end

  def render("collaborator.json", %{collaborator: collaborator}) do
    %{email: collaborator.email,
      role: collaborator.level,
      invited: collaborator.invited,
      code: collaborator.code
    }
  end

  defp render_one(project) do
    %{id: project.id,
      name: project.name,
      updated_at: project.updated_at}
  end
end
