defmodule Ask.OAuthHelperController do
  use Ask.Web, :controller

  plug Addict.Plugs.Authenticated when action in [:index]
  plug :put_layout, false

  def index(conn, %{"code" => code, "state" => provider_name}) do
    user = User.Helper.current_user(conn)
    user = Repo.get(Ask.User, user.id)

    token = user |> assoc(:oauth_tokens) |> Repo.get_by(provider: provider_name)

    if token == nil do
      provider = Ask.Channel.provider(provider_name)
      access_token = provider.oauth2_authorize(code, "http://app.ask.dev/oauth_helper")
      |> Map.from_struct

      user
      |> build_assoc(:oauth_tokens)
      |> Ask.OAuthToken.changeset(%{provider: provider_name, access_token: access_token})
      |> Repo.insert!
    end

    render conn, "index.html"
  end

  def index(conn, _params) do
    render conn, "index.html"
  end
end
