defmodule Ask.Plugs.ApiAuthenticated do
  import Plug.Conn
  import Phoenix.Controller

  alias Ask.Repo
  alias Ask.User

  def init(default), do: default

  def call(conn, _) do
    conn = case Mix.env do
      :test ->
        test_user = conn.private[:test_user]
        conn |> assign(:current_user, test_user)
      _ ->
        conn
    end

    case conn.assigns[:current_user] do
      nil  ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Unauthorized"})
        |> halt
      user ->
        case Repo.get(User, user.id) do
          nil ->
            conn
            |> assign(:current_user, nil)
            |> put_status(:unauthorized)
            |> json(%{error: "Unauthorized"})
            |> halt
          user -> assign(conn, :current_user, user)
        end
    end
  end
end
