defmodule Ask.UserController do
  use Ask.Web, :api_controller

  alias Ask.{User}

  def update(conn, %{"user" => user_params}) do
    user = conn |> current_user
    new_onboarding = case user_params["onboarding"] do
                        nil -> user.onboarding
                        _ -> Map.merge(user.onboarding, user_params["onboarding"])
                     end
    changeset = User.changeset(user)
    changeset = User.changeset(changeset, %{onboarding: new_onboarding})
    case Repo.update(changeset) do
      {:ok, user} ->
        conn
        |> render("user.json", user: user)
      {:error, changeset} ->
        conn
        |> render("error.json", changeset: changeset)
    end
  end

end
