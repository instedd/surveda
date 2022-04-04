defmodule Ask.Coherence.SessionController do
  @moduledoc """
  Handle the authentication actions.

  Module used for the session controller when the parent project does not
  generate controllers. Most of the work is done by the
  `Coherence.SessionControllerBase` inclusion.
  """
  use Ask.Coherence, :controller
  use Coherence.SessionControllerBase, schemas: Ask.Coherence.Schemas

  alias Ask.{Repo, User}

  @guisso Application.get_env(:ask, :guisso, Guisso)

  plug :layout_view,
    layout: {Ask.Coherence.LayoutView, :app},
    view: Coherence.SessionView,
    caller: __MODULE__

  plug :redirect_logged_in when action in [:new, :create]
  plug :guisso_authentication when action in [:new]

  defp guisso_authentication(conn, _) do
    if @guisso.enabled? do
      conn
      |> @guisso.request_auth_code(conn.params["redirect"])
      |> halt()
    else
      conn
    end
  end

  def oauth_callback(conn, params) do
    {:ok, email, name, redirect} = @guisso.request_auth_token(conn, params)
    user = find_or_create_user(email, name)

    conn
    |> Coherence.Authentication.Session.create_login(user, id_key: Config.schema_key())
    |> put_flash(:notice, "Signed in successfully.")
    |> redirect(to: redirect || "/")
  end

  defp find_or_create_user(email, name) do
    case Repo.one(from u in User, where: field(u, :email) == ^email) do
      nil ->
        %User{}
        |> User.changeset(%{email: email, name: name, password: UUID.uuid4()})
        |> Repo.insert!()

      user ->
        if user.name != name && name != nil && name != "" do
          user
          |> User.changeset(%{name: name})
          |> Repo.update!()
        else
          user
        end
    end
  end

  @doc """
  Logout the user.

  Delete the user's session, from an API call. Track the logout and delete the rememberable cookie,
  but don't redirect since that's a responsibility of the SPA.
  """
  def api_delete(conn, _params) do
    conn
    |> logout_user()
    |> send_resp(204, "")
  end
end
