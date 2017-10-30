defmodule User.Helper do
  import Ecto
  import Ecto.Query
  alias Ask.{Repo, Project}
  alias Ask.UnauthorizedError

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
    memberships = project
                  |> assoc(:project_memberships)
                  |> where([m], m.user_id == ^user_id)
                  |> Repo.all
    case memberships do
      [] -> raise UnauthorizedError, conn: conn
      _ -> project
    end
  end

  # Checks that the current user belongs to the given project,
  # as either an owner or editor, but not as a reader.
  #
  # Use this method on create, update, delete and other controller actions
  # that perform a change on a resource related to a project.
  def authorize_change(project, conn) do
    user_id = current_user(conn).id
    memberships = project
                  |> assoc(:project_memberships)
                  |> where([m], m.user_id == ^user_id and (m.level == "owner" or m.level == "editor"))
                  |> Repo.all
    case memberships do
      [] -> raise UnauthorizedError, conn: conn
      _ -> project
    end
  end

  def authorize_owner(project, %{assigns: %{skip_auth: true}}) do
    project
  end
  def authorize_owner(project, conn) do
    user_id = current_user(conn).id
    memberships = project
                  |> assoc(:project_memberships)
                  |> where([m], m.user_id == ^user_id and m.level == "owner")
                  |> Repo.all
    case memberships do
      [] -> raise UnauthorizedError, conn: conn
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
  end

  # Loads a project, and checks that the current user its owner.
  def load_project_for_owner(conn, project_id) do
    Project
    |> Repo.get!(project_id)
    |> authorize_owner(conn)
  end

  def authorize_channel(channel, conn) do
    if channel.user_id != current_user(conn).id do
      raise UnauthorizedError, conn: conn
    end
    channel
  end

  def check_target_collaborator_is_not_owner(membership, conn) do
    case membership.level do
      "owner" -> raise UnauthorizedError, conn: conn
      _ -> membership
    end
  end
end
