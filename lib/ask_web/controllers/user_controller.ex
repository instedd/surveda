defmodule AskWeb.UserController do
  use AskWeb, :api_controller

  alias Ask.{User}

  def settings(conn, _params) do
    user = conn |> current_user
    settings = user.settings
    render(conn, "settings.json", settings: settings)
  end

  def update_settings(conn, user_params) do
    user = conn |> current_user

    # changeset is made in 2 passes because is not posible a deep merge between a %User{} and a map (user_params)
    settings = %{settings: DeepMerge.deep_merge(user.settings, user_params["settings"] || %{})}
    user_params = Map.delete(user_params, "settings")

    first_changeset = User.changeset(user, user_params)
    changeset = User.changeset(first_changeset, settings)

    case Repo.update(changeset) do
      {:ok, user} ->
        conn
        |> render("settings.json", settings: user.settings)

      {:error, changeset} ->
        conn
        |> render("error.json", changeset: changeset)
    end
  end
end
