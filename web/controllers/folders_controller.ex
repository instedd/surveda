defmodule Ask.FoldersController do
  use Ask.Web, :api_controller

  alias Ask.{Project, Folder}

  def create(conn, params = %{"project_id" => project_id}) do
    project = Project
    |> Repo.get!(project_id)
    
    folder_params = Map.get(params, "folder", %{})

    %Folder{}
    |> Folder.changeset(folder_params)
    |> Repo.insert()
    |> case do
      {:ok, folder} ->
        conn 
        |> put_status(:created)
        # |> put_resp_header("location", folder_path(conn, :show, folder))
        |> render("show.json", folder: folder)

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Ask.ChangesetView, "error.json", changeset: changeset)
    end
  end
end