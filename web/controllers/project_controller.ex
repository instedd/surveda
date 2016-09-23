defmodule Ask.ProjectController do
  use Ask.Web, :api_controller

  alias Ask.Project

  def index(conn, _params) do
    projects = conn
    |> current_user
    |> assoc(:projects)
    |> Repo.all
    render(conn, "index.json", projects: projects)
  end

  def create(conn, %{"project" => project_params}) do
    changeset = conn
    |> current_user
    |> build_assoc(:projects)
    |> Project.changeset(project_params)

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
    project = Repo.get!(Project, id)
    if authorized_for(conn, project) do
      render(conn, "show.json", project: project)
    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Forbidden"})
    end
  end

  def update(conn, %{"id" => id, "project" => project_params}) do
    project = Repo.get!(Project, id)
    if authorized_for(conn, project) do
      changeset = Project.changeset(project, project_params)

      case Repo.update(changeset) do
        {:ok, project} ->
          render(conn, "show.json", project: project)
        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> render(Ask.ChangesetView, "error.json", changeset: changeset)
      end
    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Forbidden"})
    end
  end

  def delete(conn, %{"id" => id}) do
    project = Repo.get!(Project, id)

    if authorized_for(conn, project) do
      # Here we use delete! (with a bang) because we expect
      # it to always work (and if it does not, it will raise).
      Repo.delete!(project)

      send_resp(conn, :no_content, "")
    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Forbidden"})
    end
  end

  defp authorized_for(conn, project) do
    project.user_id == current_user(conn).id
  end

end
