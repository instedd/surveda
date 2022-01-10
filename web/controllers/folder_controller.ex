defmodule Ask.FolderController do
  use Ask.Web, :api_controller
  use Ask.Web, :append_assigns_to_action

  alias Ask.{Folder, Logger, ActivityLog, Project}
  alias Ecto.Multi

  plug :assign_project when action in [:index, :show]
  plug :assign_project_for_change when action in [:create, :set_name, :delete]

  def create(conn, %{"folder" => %{"name" => name}}, %{project: project}) do
    Multi.new()
    |> Multi.insert(:folder, Folder.changeset(%Folder{}, %{name: name, project_id: project.id}))
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
        |> put_view(Ask.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end

  def index(conn, _params, %{project: project}) do
    folders = (from f in Folder,
          where: f.project_id == ^project.id)
    |> Repo.all

    conn
    |> render("index.json", folders: folders)
  end

  def show(conn, %{"id" => folder_id}, %{project: project}) do
    folder = load_folder(project, folder_id)
    |> Repo.preload(:panel_surveys)
    |> Repo.preload(:surveys)

    render(conn, "show.json", folder: folder)
  end

  def delete(conn, %{"id" => folder_id}, %{project: project}) do
    folder = load_folder(project, folder_id)

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
        |> put_view(Ask.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end

  def set_name(conn, %{"folder_id" => folder_id, "name" => name}, %{project: project}) do
    folder = load_folder(project, folder_id)

    result =
      Multi.new()
      |> Multi.update(:set_name, Folder.changeset(folder, %{name: name}))
      |> Multi.insert(:rename_log, ActivityLog.rename_folder(project, conn, folder, folder.name, name))
      |> Repo.transaction()

    case result do
      {:ok, _} ->
        send_resp(conn, :no_content, "")

      {:error, _, changeset, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(Ask.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end

  defp load_folder(project, folder_id) do
    project
    |> assoc(:folders)
    |> Repo.get!(folder_id)
  end
end
