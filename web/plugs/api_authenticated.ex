defmodule Ask.Plugs.ApiAuthenticated do
  import Plug.Conn
  import Phoenix.Controller

  def init(default), do: default

  def call(conn, _) do
    conn = fetch_session(conn)
    case get_session(conn, :current_user) do
      nil -> conn |> put_status(:forbidden) |> json(%{error: "Forbidden"}) |> halt
      user -> assign(conn, :current_user, user)
    end
  end
end
