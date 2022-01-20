defmodule Ask.Coherence.RegistrationControllerTest do
  use Ask.ConnCase
  use Ask.MockGuissoCase

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

  test "create transforms pending invites into project memberships", %{conn: conn} do
    # disable_guisso()

    project = insert(:project)
    invite = insert(:invite, project: project, email: "someone@ask.dev", level: "admin")

    conn = post conn, registration_path(conn, :create, registration: %{
      email: "someone@ask.dev",
      name: "Nobody",
      password: "secret",
      password_confirmation: "secret",
    })
    assert redirected_to(conn, 302) == "/"

    assert user = Repo.one(from u in Ask.User, where: u.email == "someone@ask.dev")
    assert Repo.one(from m in Ask.ProjectMembership, where: m.user_id == ^user.id and m.project_id == ^project.id)
    refute Ask.Invite |> Repo.get(invite.id)
  end

  test "confirmation_sent", %{conn: conn} do
    conn = get conn, registration_path(conn, :confirmation_sent)
    assert html_response(conn, 200)
  end

  test "confirmation_expired", %{conn: conn} do
    conn = get conn, registration_path(conn, :confirmation_expired)
    assert html_response(conn, 200)
  end
end
