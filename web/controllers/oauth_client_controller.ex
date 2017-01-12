defmodule Ask.OAuthClientController do
  use Ask.Web, :controller

  plug Addict.Plugs.Authenticated
  plug :put_layout, false

  def index(conn, _params) do
    user = get_current_user(conn)
    auths = user |> assoc(:oauth_tokens) |> Repo.all

    render conn, "index.json", authorizations: auths
  end

  def delete(conn, params = %{"id" => provider}) do
    user = get_current_user(conn)

    user
    |> assoc(:oauth_tokens)
    |> Repo.get_by!(provider: provider)
    |> Repo.delete!

    keep_channels = params
    |> Map.get("keep_channels", false)
    keep_channels = keep_channels == true || keep_channels == "true"

    unless keep_channels do
      user
      |> assoc(:channels)
      |> where([c], c.provider == ^provider)
      |> Repo.all
      |> Enum.each(&Repo.delete(&1))
    end

    send_resp(conn, :no_content, "")
  end

  def synchronize(conn, _params) do
    user = get_current_user(conn)

    user
    |> assoc(:oauth_tokens)
    |> Repo.all
    |> Enum.each(fn token ->
      provider = Ask.Channel.provider(token.provider)
      provider.sync_channels(user.id)
    end)

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

      provider.sync_channels(user.id)
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
