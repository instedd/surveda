defmodule Ask.RespondentControllerTest do

  use Ask.ConnCase
  use Ask.TestHelpers

  alias Ask.{Invite}

  setup %{conn: conn} do
    user = insert(:user)
    conn = conn
      |> put_private(:test_user, user)
      |> put_req_header("accept", "application/json")

    {:ok, conn: conn, user: user}
  end

  test "create invite when inviting user", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    code = "ABC1234"
    level = "reader"
    email = "user@instedd.com.ar"
    get conn, invite_path(conn, :invite, %{"code" => code, "level" => level, "email" => email, "project_id" => project.id})
    invite = Invite |> last |> Repo.one
    assert(invite.level == level && invite.code == code && invite.project_id == project.id && invite.email == email)
  end

  test "invites user", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    code = "ABC1234"
    level = "reader"
    email = "user@instedd.com.ar"
    conn = get conn, invite_path(conn, :invite, %{"code" => code, "level" => level, "email" => email, "project_id" => project.id})
    assert json_response(conn, 200) == %{
      "data" => %{
        "project_id" => project.id,
        "code" => code,
        "level" => level,
        "email" => email
      }
    }
  end
end
