defmodule Ask.OAuthTokenServerTest do
  use Ask.ModelCase
  alias Ask.OAuthTokenServer

  setup do
    OAuthTokenServer.start_link
    :ok
  end

  test "get a token" do
    user = insert(:user)
    token = insert(:oauth_token, user: user)

    access_token = OAuthTokenServer.get_token("test", user.id)
    assert %OAuth2.AccessToken{} = access_token
    assert token.access_token["access_token"] == access_token.access_token

    token = Ask.OAuthToken |> Repo.get(token.id)
    assert token.access_token["access_token"] == access_token.access_token
  end

  test "refresh an about to expire token" do
    user = insert(:user)
    token = insert(:oauth_token, user: user)

    access_token1 = OAuthTokenServer.get_token("test", user.id)

    token
    |> Ask.OAuthToken.changeset(%{expires_at: Timex.now |> Timex.add(Timex.Duration.from_seconds(5))})
    |> Repo.update!

    access_token2 = OAuthTokenServer.get_token("test", user.id)
    refute access_token2.access_token == access_token1.access_token

    token = Ask.OAuthToken |> Repo.get(token.id)
    assert token.access_token["access_token"] == access_token2.access_token
  end
end
