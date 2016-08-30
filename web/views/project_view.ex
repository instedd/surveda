defmodule Ask.ProjectView do
  use Ask.Web, :view

  def render("index.json", %{projects: projects}) do
    %{data: render_many(projects, Ask.ProjectView, "project.json")}
  end

  def render("show.json", %{project: project}) do
    %{data: render_one(project, Ask.ProjectView, "project.json")}
  end

  def render("project.json", %{project: project}) do
    %{id: project.id,
      user_id: project.user_id,
      name: project.name}
  end
end
