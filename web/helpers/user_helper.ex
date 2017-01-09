defmodule User.Helper do
  import Ecto
  import Ecto.Query
  alias Ask.Repo
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

  def authorize_channel(channel, conn) do
    if channel.user_id != current_user(conn).id do
      raise UnauthorizedError, conn: conn
    end
    channel
  end
end
