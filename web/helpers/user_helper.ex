defmodule User.Helper do
  import Ecto
  import Ecto.Query
  alias Ask.Repo
  alias Ask.UnauthorizedError

  def current_user(conn) do
    conn.assigns.current_user
  end

  def authorize(project, conn) do
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
