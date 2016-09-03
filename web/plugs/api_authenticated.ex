defmodule Ask.Plugs.ApiAuthenticated do
  import Plug.Conn
  import Phoenix.Controller

  def init(default), do: default

  def call(conn, _) do
    case fetch_current_user(conn) do
      nil -> conn |> put_status(:forbidden) |> json(%{error: "Forbidden"}) |> halt
      user -> assign(conn, :current_user, user)
    end
  end

  defp fetch_current_user(conn) do
    case Mix.env do
      :test ->
        conn.private[:test_user]
      _ ->
        get_session(conn, :current_user)
      end
  end
end
