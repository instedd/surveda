defmodule Ask.PageController do
  use Ask.Web, :controller
  import Ask.Router.Helpers
  plug Guisso.SSO, session_controller: Ask.Coherence.SessionController

  def index(conn, params = %{"path" => path}) do
    explicit = params["explicit"]
    if params["locale"] do
      Gettext.put_locale(Ask.Gettext, params["locale"])
    end
    user = conn.assigns[:current_user]

    case {path, user, explicit} do
      {_, _, "true"} ->
        conn |> render("landing.html", current_locale: current_locale_description(Gettext.get_locale(Ask.Gettext)))
      {[], nil, _} ->
        conn |> render("landing.html", current_locale: current_locale_description(Gettext.get_locale(Ask.Gettext)))
      {_, nil, _} ->
        conn |> redirect(to: session_path(conn, :new, redirect: current_path(conn)))
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

  defp current_locale_description(locale) do
    case locale do
      "en" -> "English (en)"
      "es" -> "Español (es)"
      "fr" -> "Français (fr)"
      _ -> "English (en)"
    end
  end
end
