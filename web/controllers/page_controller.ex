defmodule Ask.PageController do
  use Ask.Web, :controller

  def index(conn, %{"path" => path}) do
    user = get_session(conn, :current_user)

    case {path, user} do
      {[], nil} ->
        conn
        |> render("landing.html")
      {path, nil} ->
        conn
        |> redirect(to: "/login?redirect=/#{Enum.join path, "/"}")
      _ ->
        conn
        |> assign(:current_user, user)
        |> render("index.html", user: user)
    end
  end
end
