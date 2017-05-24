defmodule Ask.PageController do
  use Ask.Web, :controller
  import Ask.Router.Helpers

  def index(conn, params = %{"path" => path}) do
    explicit = params["explicit"]
    user = conn.assigns[:current_user]

    filtered_params_string = "?" <> Enum.reduce(params, "", fn({key, value}, acc) ->
      if key != "path" do
        str = case acc do
          "" -> acc
          _  -> acc <> "&"
        end
        str <> key <> "=" <> value
      else
        acc
      end
    end)

    case {path, user, explicit} do
      {_, _, "true"} ->
        conn |> render("landing.html")
      {[], nil, _} ->
        conn |> render("landing.html")
      {path, nil, _} ->
        conn |> redirect(to: "#{session_path(conn, :new)}?redirect=/#{Enum.join path, "/"}#{filtered_params_string}")
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
