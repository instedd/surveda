defmodule Ask.PageController do
  use Ask.Web, :controller
  import Ask.Router.Helpers

  def index(conn, %{"path" => path}) do
    user = conn.assigns[:current_user]

    case {path, user} do
      {[], nil} ->
        conn |> render("landing.html")
      {path, nil} ->
        conn |> redirect(to: "#{session_path(conn, :new)}?redirect=/#{Enum.join path, "/"}")
      _ ->
        conn |> render("index.html", user: user, body_class: compute_body_class(path))
    end
  end

  # Check if the URL corresponds to a project.
  # If so, load it to get the colour scheme.
  # User permissions don't matter much here because they will
  # be checked later (from the app itself) and this just loads
  # a colour scheme (it's not sensitive data)
  defp compute_body_class(path) do
    case path do
      ["projects", project_id | _ ] ->
        project = Repo.get(Ask.Project, project_id)
        if project && project.colour_scheme == "better_data_for_health" do
          "bdfh"
        else
          nil
        end
      _ ->
        nil
    end
  end
end