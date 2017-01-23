defmodule Ask.PageController do
  use Ask.Web, :controller

  def index(conn, %{"path" => path}) do
    user = conn.assigns[:current_user]

    case {path, user} do
      {[], nil} ->
        conn |> render("landing.html")
      {path, nil} ->
        #conn |> redirect(to: "/login?redirect=/#{Enum.join path, "/"}")
      _ ->
        conn |> render("index.html", user: user)
    end
  end
end