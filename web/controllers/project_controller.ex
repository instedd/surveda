defmodule Ask.ProjectController do
  use Ask.Web, :api_controller

  alias Ask.{Project, Survey, ProjectMembership}

  def index(conn, _params) do
    projects = conn
    |> current_user
    |> assoc(:projects)
    |> Repo.all

    running_surveys_by_project = Repo.all(from p in Project,
      join: s in Survey,
      select: {p.id, count(s.id)},
      where: s.project_id == p.id and s.state == "running",
      group_by: p.id) |> Enum.into(%{})

    render(conn, "index.json", projects: projects, running_surveys_by_project: running_surveys_by_project)
  end

  def create(conn, %{"project" => project_params}) do
    user_changeset = conn
    |> current_user
    |> change

    membership_changeset = %ProjectMembership{}
    |> change
    |> put_assoc(:user, user_changeset)
    |> put_change(:level, "owner")

    changeset = Project.changeset(%Project{}, project_params)
    |> put_assoc(:project_memberships, [membership_changeset])

    case Repo.insert(changeset) do
      {:ok, project} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", project_path(conn, :show, project))
        |> render("show.json", project: project)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Ask.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    project = Project
    |> Repo.get!(id)
    |> authorize(conn)

    render(conn, "show.json", project: project)
  end

  def update(conn, %{"id" => id, "project" => project_params}) do
    changeset = Project
    |> Repo.get!(id)
    |> authorize(conn)
    |> Project.changeset(project_params)

    case Repo.update(changeset) do
      {:ok, project} ->
        render(conn, "show.json", project: project)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Ask.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    Project
    |> Repo.get!(id)
    |> authorize(conn)
    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    |> Repo.delete!()

    send_resp(conn, :no_content, "")
  end

  def autocomplete_vars(conn, %{"project_id" => id, "text" => text}) do
    Project
    |> Repo.get!(id)
    |> authorize(conn)

    text = text |> String.downcase

    vars = (from v in Ask.QuestionnaireVariable, where: v.project_id == ^id)
    |> Repo.all
    |> Enum.map(&(&1.name))
    |> Enum.filter(&(&1 |> String.downcase |> String.starts_with?(text)))
    |> Enum.filter(&(&1 != text))

    conn |> json(vars)
  end

  def collaborators(conn, %{"project_id" => id}) do
    project = Project
    |> Repo.get!(id)
    |> authorize(conn)

    render(conn, "show.json", project: project)
  end
end
