defmodule Ask.OAuthTokenServer do
  use GenServer
  alias Ask.{OAuthToken, Repo}

  @server_ref {:global, __MODULE__}

  def start_link do
    GenServer.start_link(__MODULE__, [], name: @server_ref)
  end

  def get_token(provider, base_url, user_id) do
    GenServer.call(@server_ref, {:get_token, provider, base_url, user_id})
  end

  def handle_call({:get_token, provider, base_url, user_id}, _from, state) do
    token = OAuthToken
    |> Repo.get_by(provider: provider, base_url: base_url, user_id: user_id)

    token = if about_to_expire?(token) do
      refresh(provider, base_url, token)
    else
      token
    end

    {:reply, OAuthToken.access_token(token), state}
  end

  defp about_to_expire?(token) do
    limit = Timex.now |> Timex.add(Timex.Duration.from_minutes(1))
    Timex.before?(token.expires_at, limit)
  end

  defp refresh(provider_name, base_url, token) do
    provider = Ask.Channel.provider(provider_name)
    access_token = provider.oauth2_refresh(OAuthToken.access_token(token), base_url)

    token
    |> OAuthToken.from_access_token(access_token)
    |> Repo.update!
  end
end
