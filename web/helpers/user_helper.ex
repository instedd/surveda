defmodule User.Helper do
  alias Ask.UnauthorizedError

  def current_user(conn) do
    conn.assigns.current_user
  end

  def authorize(project, conn) do
    if project.user_id != current_user(conn).id do
      raise UnauthorizedError, conn: conn
    end
    project
  end
end
