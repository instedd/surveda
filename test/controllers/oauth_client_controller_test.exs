defmodule Ask.OAuthHelperControllerTest do
  use Ask.ConnCase

  setup %{conn: conn} do
    user = insert(:user)
    conn = conn
      |> post(login_path(conn, :login, %{email: user.email, password: "1234"}))
    {:ok, conn: conn, user: user}
  end

  test "authorize channel", %{conn: conn, user: user} do
    get conn, o_auth_client_path(conn, :callback, %{code: "1234", state: "test"})
    token = user |> assoc(:oauth_tokens) |> Repo.get_by(provider: "test")
    assert token != nil
    assert token.expires_at != nil
    assert Timex.after?(token.expires_at, Timex.now)
    assert Timex.before?(token.expires_at, Timex.now |> Timex.add(Timex.Duration.from_seconds(3601)))
    assert %OAuth2.AccessToken{} = OAuth2.AccessToken.new(token.access_token)
  end

  test "channels are synchronized after authorization", %{conn: conn, user: user} do
    get conn, o_auth_client_path(conn, :callback, %{code: "1234", state: "test"})
    channels = user |> assoc(:channels) |> Repo.all
    assert 1 = length(channels)
  end

  test "list user authorizations", %{conn: conn, user: user} do
    insert(:oauth_token, user: user, provider: "provider1")
    insert(:oauth_token, user: user, provider: "provider2")
    insert(:oauth_token)

    conn = get conn, o_auth_client_path(conn, :index)
    assert json_response(conn, 200)["data"] == ["provider1", "provider2"]
  end

  test "delete user authorization", %{conn: conn, user: user} do
    p1 = insert(:oauth_token, user: user, provider: "provider1")
    p2 = insert(:oauth_token, user: user, provider: "provider2")

    conn = delete conn, o_auth_client_path(conn, :delete, p1.provider)
    assert response(conn, :no_content)

    tokens = user |> assoc(:oauth_tokens) |> Repo.all
    assert [p2.id] == tokens |> Enum.map(fn t -> t.id end)
  end

  test "delete channels when an authorization is deleted", %{conn: conn, user: user} do
    insert(:oauth_token, user: user, provider: "provider")
    channel = insert(:channel, user: user, provider: "provider")

    delete conn, o_auth_client_path(conn, :delete, "provider")

    refute Ask.Channel |> Repo.get(channel.id)
  end

  test "delete channel even if it's being used by a survey", %{conn: conn, user: user} do
    insert(:oauth_token, user: user, provider: "provider")
    channel = insert(:channel, user: user, provider: "provider")
    survey = insert(:survey)
    insert(:survey_channel, survey: survey, channel: channel)

    delete conn, o_auth_client_path(conn, :delete, "provider")

    refute Ask.Channel |> Repo.get(channel.id)
    assert [] = Ask.SurveyChannel |> Repo.all
  end
end
