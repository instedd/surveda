defmodule Ask.MembershipController do
  use Ask.Web, :api_controller

  alias Ask.{ProjectMembership, User, UnauthorizedError, ActivityLog}
  alias Ecto.Multi

  def remove(conn, %{"project_id" => project_id, "email" => email}) do
    conn
    |> load_project_for_change(project_id)

    user = Repo.one(from u in User, where: u.email == ^email)

    project_membership =
      ProjectMembership
      |> where([pm], pm.user_id == ^user.id and pm.project_id == ^project_id)
      |> preload(:project)
      |> Repo.one()
      |> check_target_collaborator_is_not_owner()

    multi =
      Multi.new()
      |> Multi.delete(:delete, project_membership)
      |> Multi.insert(
        :insert,
        ActivityLog.remove_collaborator(
          project_membership.project,
          conn,
          user,
          project_membership.level
        )
      )
      |> Repo.transaction()

    case multi do
      {:ok, _} ->
        send_resp(conn, :no_content, "")

      {:error, _, error_changeset, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(Ask.ChangesetView)
        |> render("error.json", changeset: error_changeset)
    end
  end

  def update(_, %{"level" => "owner"}) do
    raise UnauthorizedError
  end

  def update(conn, %{"project_id" => project_id, "level" => new_level, "email" => email}) do
    conn
    |> load_project_for_change(project_id)

    perform_update(conn, project_id, new_level, email)
  end

  def perform_update(conn, project_id, new_level, email) do
    user = Repo.one(from u in User, where: u.email == ^email)

    project_membership =
      ProjectMembership
      |> where([pm], pm.user_id == ^user.id and pm.project_id == ^project_id)
      |> preload(:project)
      |> Repo.one()

    update_changeset =
      project_membership
      |> check_target_collaborator_is_not_owner()
      |> ProjectMembership.changeset(%{level: new_level})
      |> ProjectMembership.authorize(user_level(project_id, current_user(conn).id))

    multi =
      Multi.new()
      |> Multi.update(:update, update_changeset)
      |> Multi.insert(
        :insert,
        ActivityLog.edit_collaborator(
          project_membership.project,
          conn,
          user,
          project_membership.level,
          new_level
        )
      )
      |> Repo.transaction()

    case multi do
      {:ok, _} ->
        send_resp(conn, :no_content, "")

      {:error, _, error_changeset, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(Ask.ChangesetView)
        |> render("error.json", changeset: error_changeset)
    end
  end
end
