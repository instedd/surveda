defmodule User.Helper do
  import Ecto
  import Ecto.Query
  alias Ask.Repo
  alias Ask.ProjectMembership
  alias Ask.UnauthorizedError

  def current_user(conn) do
    conn.assigns.current_user
  end

  def authorize(project, conn) do
    user_id = current_user(conn).id
    memberships = project |> assoc(:project_memberships) |> where([m], m.user_id == ^user_id) |> Repo.all
    if !Enum.any?(memberships, fn m -> m.level == "owner" or m.level == "editor" end) do
      raise UnauthorizedError, conn: conn
    end
    project
  end
end
