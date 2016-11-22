defmodule Ask.OAuthClientController do
  use Ask.Web, :controller

  plug Addict.Plugs.Authenticated
  plug :put_layout, false

  def index(conn, _params) do
    user = get_current_user(conn)
    auths = user |> assoc(:oauth_tokens) |> Repo.all

    render conn, "index.json", authorizations: auths
  end

  def delete(conn, %{"id" => provider}) do
    conn
    |> get_current_user
    |> assoc(:oauth_tokens)
    |> Repo.get_by!(provider: provider)
    |> Repo.delete!

    send_resp(conn, :no_content, "")
  end

  def callback(conn, %{"code" => code, "state" => provider_name}) do
    user = get_current_user(conn)
    token = user |> assoc(:oauth_tokens) |> Repo.get_by(provider: provider_name)

    if token == nil do
      provider = Ask.Channel.provider(provider_name)
      access_token = provider.oauth2_authorize(code, "#{url(conn)}#{conn.request_path}", callback_url(conn, :callback, provider_name))

      user
      |> build_assoc(:oauth_tokens, provider: provider_name)
      |> Ask.OAuthToken.from_access_token(access_token)
      |> Repo.insert!
    end

    render conn, "callback.html"
  end

  def callback(conn, _params) do
    render conn, "callback.html"
  end

  defp get_current_user(conn) do
    user = User.Helper.current_user(conn)
    Repo.get(Ask.User, user.id)
  end
end
