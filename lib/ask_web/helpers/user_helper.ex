defmodule User.Helper do
  import Ecto
  import Ecto.Query
  alias Ask.{Repo, Project, ProjectMembership}
  alias AskWeb.UnauthorizedError

  def current_user(nil), do: nil

  def current_user(conn) do
    case conn.assigns do
      %{current_user: user} -> user
      _ -> nil
    end
  end

  # Checks that the current user belongs to the given project,
  # with any level of membership.
  #
  # Use this method on any read-only controller action.
  def authorize(project, %{assigns: %{skip_auth: true}}) do
    project
  end

  def authorize(project, conn) do
    user_id = current_user(conn).id

    memberships =
      project
      |> assoc(:project_memberships)
      |> where([m], m.user_id == ^user_id)
      |> Repo.all()

    case memberships do
      [] -> raise UnauthorizedError
      _ -> project
    end
  end

  # Checks that the current user belongs to the given project,
  # as either an owner, admin or editor, but not as a reader.
  #
  # Use this method on create, update, delete and other controller actions
  # that perform a change on a resource related to a project.
  def authorize_change(project, conn) do
    user_id = current_user(conn).id

    memberships =
      project
      |> assoc(:project_memberships)
      |> where(
        [m],
        m.user_id == ^user_id and
          (m.level == "owner" or m.level == "editor" or m.level == "admin")
      )
      |> Repo.all()

    case memberships do
      [] -> raise UnauthorizedError
      _ -> project
    end
  end

  def authorize_admin(project, %{assigns: %{skip_auth: true}}) do
    project
  end

  def authorize_admin(project, conn) do
    user_id = current_user(conn).id

    memberships =
      project
      |> assoc(:project_memberships)
      |> where([m], m.user_id == ^user_id and (m.level == "owner" or m.level == "admin"))
      |> Repo.all()

    case memberships do
      [] -> raise UnauthorizedError
      _ -> project
    end
  end

  # Loads a project, and checks that the current user belongs to
  # it with any access level.
  def load_project(conn, project_id) do
    Project
    |> Repo.get!(project_id)
    |> authorize(conn)
  end

  # Loads a project, and checks that the current user belongs to
  # it as either and owner or editor, but not as a reader.
  def load_project_for_change(conn, project_id) do
    Project
    |> Repo.get!(project_id)
    |> authorize_change(conn)
    |> validate_project_not_archived(conn)
  end

  # Loads a project, and checks that the current user its owner.
  def load_project_for_owner(conn, project_id) do
    Project
    |> Repo.get!(project_id)
    |> authorize_admin(conn)
  end

  def validate_project_not_archived(project, conn) do
    if project.archived do
      raise UnauthorizedError, conn: conn
    else
      project
    end
  end

  def authorize_channel(channel, conn) do
    if channel.user_id != current_user(conn).id do
      raise UnauthorizedError
    end

    channel
  end

  def check_target_collaborator_is_not_owner(membership) do
    case membership.level do
      "owner" -> raise UnauthorizedError
      _ -> membership
    end
  end

  def user_level(project_id, user_id) do
    membership =
      ProjectMembership
      |> where([m], m.user_id == ^user_id and m.project_id == ^project_id)
      |> Repo.one()

    if membership, do: membership.level, else: nil
  end
end
