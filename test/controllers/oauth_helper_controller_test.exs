defmodule Ask.OAuthHelperControllerTest do
  use Ask.ConnCase

  setup %{conn: conn} do
    user = insert(:user)
    conn = conn
      |> post(login_path(conn, :login, %{email: user.email, password: "1234"}))
    {:ok, conn: conn, user: user}
  end

  test "authorize channel", %{conn: conn, user: user} do
    get conn, o_auth_helper_path(conn, :index, %{code: "1234", state: "test"})
    token = user |> assoc(:oauth_tokens) |> Repo.get_by(provider: "test")
    assert token != nil
    assert token.expires_at != nil
    assert Timex.after?(token.expires_at, Timex.now)
    assert Timex.before?(token.expires_at, Timex.now |> Timex.add(Timex.Duration.from_seconds(3601)))
    assert %OAuth2.AccessToken{} = OAuth2.AccessToken.new(token.access_token)
  end
end
