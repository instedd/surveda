defmodule Ask.ProjectView do
  use Ask.Web, :view

  def render("index.json", %{projects: projects, running_surveys_by_project: running_surveys_by_project, levels_by_project: levels_by_project}) do
    rendered = projects |> Enum.map(fn(project) ->
      level = levels_by_project |> Map.get(project.id, "reader")
      one = render_one(project)
      one
      |> Map.put(:running_surveys, Map.get(running_surveys_by_project, project.id, 0))
      |> Map.put(:read_only, level == "reader" || project.archived)
      |> Map.put(:owner, level == "owner")
    end)
    %{data: rendered}
  end

  def render("show.json", %{project: project, read_only: read_only, owner: owner}) do
    rendered = render_one(project, Ask.ProjectView, "project.json")
    |> Map.put(:read_only, read_only)
    |> Map.put(:owner, owner)
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
      updated_at: project.updated_at,
      colour_scheme: project.colour_scheme
    }
  end
end
