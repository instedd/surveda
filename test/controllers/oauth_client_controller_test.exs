defmodule Ask.OAuthClientControllerTest do
  use Ask.ConnCase

  setup %{conn: conn} do
    user = insert(:user)

    conn = conn
      |> post(session_path(conn, :create, %{session: %{email: user.email, password: "1234"}}))
    {:ok, conn: conn, user: user}
  end

  test "authorize channel", %{conn: conn, user: user} do
    get conn, o_auth_client_path(conn, :callback, %{code: "1234", state: "test|http://test.com"})
    token = user |> assoc(:oauth_tokens) |> Repo.get_by(provider: "test", base_url: "http://test.com")
    assert token != nil
    assert token.expires_at != nil
    assert Timex.after?(token.expires_at, Timex.now)
    assert Timex.before?(token.expires_at, Timex.now |> Timex.add(Timex.Duration.from_seconds(3601)))
    assert %OAuth2.AccessToken{} = OAuth2.AccessToken.new(token.access_token)
  end

  test "channels are synchronized after authorization", %{conn: conn, user: user} do
    get conn, o_auth_client_path(conn, :callback, %{code: "1234", state: "test|http://test.com"})
    channels = user |> assoc(:channels) |> Repo.all
    assert 1 = length(channels)
  end

  test "list user authorizations", %{conn: conn, user: user} do
    insert(:oauth_token, user: user, provider: "provider1", base_url: "http://test.com")
    insert(:oauth_token, user: user, provider: "provider2", base_url: "http://bar.com")
    insert(:oauth_token)

    conn = get conn, o_auth_client_path(conn, :index)

    assert json_response(conn, 200)["data"] == [
      %{"provider" => "provider1", "baseUrl" => "http://test.com"},
      %{"provider" => "provider2", "baseUrl" => "http://bar.com"},
    ]
  end

  test "delete user authorization", %{conn: conn, user: user} do
    p1 = insert(:oauth_token, user: user, provider: "provider1", base_url: "http://test.com")
    p2 = insert(:oauth_token, user: user, provider: "provider2", base_url: "http://bar.com")

    conn = delete conn, o_auth_client_path(conn, :delete, p1.provider, base_url: "http://test.com")
    assert response(conn, :no_content)

    tokens = user |> assoc(:oauth_tokens) |> Repo.all
    assert [p2.id] == tokens |> Enum.map(fn t -> t.id end)
  end

  test "delete channels when an authorization is deleted", %{conn: conn, user: user} do
    insert(:oauth_token, user: user, provider: "provider", base_url: "http://test.com")
    channel = insert(:channel, user: user, provider: "provider", base_url: "http://test.com")

    delete conn, o_auth_client_path(conn, :delete, "provider", base_url: "http://test.com")

    refute Ask.Channel |> Repo.get(channel.id)
  end

  test "doesn't delete channels when an authorization is deleted with keep_channels = true", %{conn: conn, user: user} do
    insert(:oauth_token, user: user, provider: "provider", base_url: "http://test.com")
    channel = insert(:channel, user: user, provider: "provider", base_url: "http://test.com")

    delete conn, o_auth_client_path(conn, :delete, "provider", base_url: "http://test.com"), keep_channels: "true"

    Ask.Channel |> Repo.get!(channel.id)
  end

  test "delete channel even if it's being used by a respondent group", %{conn: conn, user: user} do
    insert(:oauth_token, user: user, provider: "provider", base_url: "http://test.com")
    channel = insert(:channel, user: user, provider: "provider", base_url: "http://test.com")
    group = insert(:respondent_group)
    insert(:respondent_group_channel, respondent_group: group, channel: channel)

    delete conn, o_auth_client_path(conn, :delete, "provider", base_url: "http://test.com")

    refute Ask.Channel |> Repo.get(channel.id)
    assert [] = Ask.RespondentGroupChannel |> Repo.all
  end

  test "synchronize channels", %{conn: conn, user: user} do
    insert(:oauth_token, user: user, provider: "test")
    get conn, o_auth_client_path(conn, :synchronize)

    channels = user
    |> assoc(:channels)
    |> Repo.all

    assert 1 = channels |> Enum.count
  end
end
