defmodule AskWeb.FolderController do
  use AskWeb, :api_controller

  alias Ask.{Folder, Logger, ActivityLog, Project}
  alias Ecto.Multi

  def create(conn, %{"project_id" => project_id, "folder" => %{"name" => name}}) do
    project =
      conn
      |> load_project_for_change(project_id)

    Multi.new()
    |> Multi.insert(:folder, Folder.changeset(%Folder{}, %{name: name, project_id: project_id}))
    |> Multi.run(:log, fn _, %{folder: folder} ->
      ActivityLog.create_folder(project, conn, folder) |> Repo.insert()
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{folder: folder}} ->
        project |> Project.touch!()

        conn
        |> put_status(:created)
        |> render("show.json", folder: folder)

      {:error, :folder, %Ecto.Changeset{} = changeset, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(AskWeb.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end

  def index(conn, %{"project_id" => project_id}) do
    project =
      conn
      |> load_project(project_id)

    folders =
      from(f in Folder,
        where: f.project_id == ^project.id
      )
      |> Repo.all()

    conn
    |> render("index.json", folders: folders)
  end

  def show(conn, %{"project_id" => project_id, "id" => folder_id}) do
    project =
      conn
      |> load_project(project_id)

    folder =
      project
      |> assoc(:folders)
      |> Repo.get!(folder_id)
      |> Repo.preload(:panel_surveys)
      |> Repo.preload(:surveys)

    render(conn, "show.json", folder: folder)
  end

  def delete(conn, %{"project_id" => project_id, "id" => folder_id}) do
    project =
      conn
      |> load_project_for_change(project_id)

    folder =
      project
      |> assoc(:folders)
      |> Repo.get!(folder_id)

    Multi.new()
    |> Multi.delete(:delete, Folder.delete_changeset(folder))
    |> Multi.insert(:log, ActivityLog.delete_folder(project, conn, folder))
    |> Repo.transaction()
    |> case do
      {:ok, _} ->
        send_resp(conn, :no_content, "")

      {:error, :delete, changeset, _} ->
        Logger.warn("Error when deleting folder #{folder.id}")

        conn
        |> put_status(:unprocessable_entity)
        |> put_view(AskWeb.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end

  def set_name(conn, %{"project_id" => project_id, "folder_id" => folder_id, "name" => name}) do
    project =
      conn
      |> load_project_for_change(project_id)

    folder =
      project
      |> assoc(:folders)
      |> Repo.get!(folder_id)

    result =
      Multi.new()
      |> Multi.update(:set_name, Folder.changeset(folder, %{name: name}))
      |> Multi.insert(
        :rename_log,
        ActivityLog.rename_folder(project, conn, folder, folder.name, name)
      )
      |> Repo.transaction()

    case result do
      {:ok, _} ->
        send_resp(conn, :no_content, "")

      {:error, _, changeset, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(AskWeb.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end
end
