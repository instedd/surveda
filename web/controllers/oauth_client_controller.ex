defmodule Ask.OAuthClientController do
  use Ask.Web, :controller

  plug :put_layout, false

  def index(conn, _params) do
    user = get_current_user(conn)
    auths = user |> assoc(:oauth_tokens) |> Repo.all

    render conn, "index.json", authorizations: auths
  end

  def delete(conn, params = %{"id" => provider, "base_url" => base_url}) do
    user = get_current_user(conn)

    user
    |> assoc(:oauth_tokens)
    |> Repo.get_by!(provider: provider, base_url: base_url)
    |> Repo.delete!

    keep_channels = params
    |> Map.get("keep_channels", false)
    keep_channels = keep_channels == true || keep_channels == "true"

    unless keep_channels do
      user
      |> assoc(:channels)
      |> where([c], c.provider == ^provider and c.base_url == ^base_url)
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
      provider.sync_channels(user.id, token.base_url)
    end)

    send_resp(conn, :no_content, "")
  end

  def callback(conn, %{"code" => code, "state" => state}) do
    [provider_name, base_url] = String.split(state, "|", parts: 2)

    user = get_current_user(conn)
    token = user |> assoc(:oauth_tokens) |> Repo.get_by(provider: provider_name, base_url: base_url)

    error = if token == nil do
      provider = Ask.Channel.provider(provider_name)
      access_token = provider.oauth2_authorize(code, "#{url(conn)}#{conn.request_path}", base_url)

      if access_token.other_params && access_token.other_params["error"] do
        access_token.other_params["error_description"] || "Error connecting to provider: #{access_token.other_params["error"]}"
      else
        user
        |> build_assoc(:oauth_tokens, provider: provider_name, base_url: base_url)
        |> Ask.OAuthToken.from_access_token(access_token)
        |> Repo.insert!

        provider.sync_channels(user.id, base_url)
        nil
      end
    end

    render conn, "callback.html", error: error
  end

  def callback(conn, _params) do
    render conn, "callback.html"
  end

  defp get_current_user(conn) do
    user = User.Helper.current_user(conn)
    Repo.get(Ask.User, user.id)
  end
end
