defmodule AskWeb.ProjectView do
  use AskWeb, :view

  def render("index.json", %{
        projects: projects,
        running_surveys_by_project: running_surveys_by_project,
        levels_by_project: levels_by_project
      }) do
    rendered =
      projects
      |> Enum.map(fn project ->
        level = levels_by_project |> Map.get(project.id, "reader")
        one = render_one(project)

        one
        |> Map.put(:running_surveys, Map.get(running_surveys_by_project, project.id, 0))
        |> Map.put(:read_only, level == "reader" || project.archived)
        |> Map.put(:owner, level == "owner")
        |> Map.put(:level, level)
      end)

    %{data: rendered}
  end

  def render("show.json", %{project: project, read_only: read_only, owner: owner, level: level}) do
    rendered =
      render_one(project, AskWeb.ProjectView, "project.json")
      |> Map.put(:read_only, read_only)
      |> Map.put(:owner, owner)
      |> Map.put(:level, level)

    %{data: rendered}
  end

  def render("project.json", %{project: project}) do
    render_one(project)
  end

  def render("collaborators.json", %{collaborators: collaborators}) do
    %{
      data: %{
        collaborators:
          render_many(collaborators, AskWeb.ProjectView, "collaborator.json", as: :collaborator)
      }
    }
  end

  def render("collaborator.json", %{collaborator: collaborator}) do
    %{
      email: collaborator.email,
      role: collaborator.level,
      invited: collaborator.invited,
      code: collaborator.code
    }
  end

  def render("activities.json", %{activities: activities, activities_count: activities_count}) do
    %{
      data: %{
        activities: render_many(activities, AskWeb.ProjectView, "activity.json", as: :activity)
      },
      meta: %{count: activities_count}
    }
  end

  def render("activity.json", %{activity: %{user: %{name: name, email: email}} = activity}) do
    render_basic("activity.json", %{activity: activity})
    |> Map.merge(%{
      user_name: name,
      user_email: email
    })
  end

  def render("activity.json", %{activity: activity}) do
    render_basic("activity.json", %{activity: activity})
  end

  defp render_basic("activity.json", %{activity: activity}) do
    %{
      remote_ip: activity.remote_ip,
      action: activity.action,
      entity_type: activity.entity_type,
      metadata: activity.metadata,
      id: activity.id,
      inserted_at: activity.inserted_at
    }
  end

  defp render_one(project) do
    %{
      id: project.id,
      name: project.name,
      updated_at: project.updated_at,
      colour_scheme: project.colour_scheme,
      timezone: project.timezone,
      initial_success_rate: project.initial_success_rate,
      eligibility_rate: project.eligibility_rate,
      response_rate: project.response_rate,
      valid_respondent_rate: project.valid_respondent_rate,
      batch_limit_per_minute: project.batch_limit_per_minute
    }
  end
end
