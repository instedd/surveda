defmodule Ask.OAuthTokenServer do
  use GenServer
  alias Ask.{OAuthToken, Repo}

  @server_ref {:global, __MODULE__}

  def start_link do
    GenServer.start_link(__MODULE__, [], name: @server_ref)
  end

  def get_token(provider, user_id) do
    GenServer.call(@server_ref, {:get_token, provider, user_id})
  end

  def handle_call({:get_token, provider, user_id}, _from, state) do
    token = OAuthToken
    |> Repo.get_by(provider: provider, user_id: user_id)

    token = if about_to_expire?(token) do
      refresh(provider, token)
    else
      token
    end

    {:reply, OAuthToken.access_token(token), state}
  end

  defp about_to_expire?(token) do
    limit = Timex.now |> Timex.add(Timex.Duration.from_minutes(1))
    Timex.before?(token.expires_at, limit)
  end

  defp refresh(provider_name, token) do
    provider = Ask.Channel.provider(provider_name)
    access_token = provider.oauth2_refresh(token.access_token)

    token
    |> OAuthToken.from_access_token(access_token)
    |> Repo.update!
  end
end
