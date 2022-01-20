defmodule Ask.Coherence.SessionControllerTest do
  use Ask.ConnCase
  use Ask.MockGuissoCase

  alias Ask.User

  test "new with guisso enabled", %{conn: conn} do
    enable_guisso()

    conn = get conn, session_path(conn, :new)
    location = redirected_to(conn, 302)
    assert location =~ ~r{^http://guisso.localhost/oauth2/authorize}

    params = URI.parse(location).query |> URI.query_decoder() |> Map.new()
    assert params["redirect_uri"] == "http://app.ask.dev/session/oauth_callback"
    assert params["response_type"] == "code"
  end

  test "new with guisso disabled", %{conn: conn} do
    disable_guisso()

    conn = get conn, session_path(conn, :new)
    assert html_response(conn, 200)
  end

  describe "oauth_callback" do
    # setup do
    #   enable_guisso()
    # end

    test "login existing user", %{conn: conn} do
      user = insert(:user, email: "someone@ask.dev", name: "John")

      GuissoMock |>
      expect(:request_auth_token, fn (_, _) ->
        {:ok, "someone@ask.dev", "Neil", nil}
      end)

      conn = get conn, session_path(conn, :oauth_callback), code: "CODE", state: "STATE"
      assert redirected_to(conn, 302) == "/"

      # synchronized the user's name
      user = User |> Repo.get!(user.id)
      assert user.name == "Neil"
    end

    test "register new user", %{conn: conn} do
      GuissoMock |>
      expect(:request_auth_token, fn (_, _) ->
        {:ok, "someone@ask.dev", "Someone", nil}
      end)

      conn = get conn, session_path(conn, :oauth_callback), code: "CODE", state: "STATE"
      assert redirected_to(conn, 302) == "/"

      # it created the user
      assert user = Repo.one(from u in User,
        where: u.email == "someone@ask.dev")
      assert user.name == "Someone"
    end

    # FIXME: the endpoint doesn't actually creates the membership?!
    # test "transforms pending invites into project memberships", %{conn: conn} do
    #   project = insert(:project)
    #   invite = insert(:invite, project: project, email: "someone@ask.dev", level: "admin")

    #   GuissoMock |>
    #   expect(:request_auth_token, fn (_, _) ->
    #     {:ok, "someone@ask.dev", "Someone", nil}
    #   end)

    #   conn = get conn, session_path(conn, :oauth_callback), code: "CODE", state: "STATE"
    #   assert redirected_to(conn, 302) == "/"

    #   # it created the user and added her to the project (and deleted the invite)
    #   assert user = Repo.one(from u in User, where: u.email == "someone@ask.dev")
    #   assert Repo.one(from m in Ask.ProjectMembership, where: m.user_id == ^user.id and m.project_id == ^project.id)
    #   refute Ask.Invite |> Repo.get(invite.id)
    # end
  end

  describe "authenticated" do
    # setup do
    #   disable_guisso()
    # end

    test "create redirects unconfirmed user to confirmation page", %{conn: conn} do
      user = insert(:user, confirmed_at: nil)

      conn = post conn, session_path(conn, :create, session: %{ "email" => user.email, "password" => "1234" })
      assert redirected_to(conn, 302) == "/registrations/confirmation_sent"
    end

    test "api_delete", %{conn: conn} do
      user = insert(:user)

      conn = conn
      |> post(session_path(conn, :create, session: %{ "email" => user.email, "password" => "1234" }))
      assert redirected_to(conn, 302)

      conn = conn
      |> recycle()
      |> delete(session_path(conn, :api_delete))
      assert conn.status == 204
    end
  end
end
