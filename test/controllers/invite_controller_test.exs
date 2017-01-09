defmodule Ask.InviteControllerTest do

  import Ecto.Query

  use Ask.ConnCase
  use Ask.TestHelpers

  alias Ask.{Invite, ProjectMembership}

  setup %{conn: conn} do
    user = insert(:user)
    conn = conn
      |> put_private(:test_user, user)
      |> put_req_header("accept", "application/json")

    {:ok, conn: conn, user: user}
  end

  test "creates invite when inviting user", %{conn: conn, user: user} do
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

  test "creates membership when accpeting invite", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    user2 = insert(:user)
    code = "ABC1234"
    level = "reader"
    invite = %{
      "project_id" => project.id,
      "code" => code,
      "level" => level,
      "email" => user2.email
    }
    Invite.changeset(%Invite{}, invite) |> Repo.insert
    conn = conn
      |> put_private(:test_user, user2)
      |> put_req_header("accept", "application/json")

    get conn, accept_invitation_path(conn, :accept_invitation, %{"code" => code})
    membership = Repo.one(from pm in ProjectMembership, where: pm.user_id == ^user2.id)
    assert membership.level == level
    assert membership.project_id == project.id
  end

  test "deletes invite after accepting", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    user2 = insert(:user)
    code = "ABC1234"
    level = "reader"
    invite = %{
      "project_id" => project.id,
      "code" => code,
      "level" => level,
      "email" => user2.email
    }
    Invite.changeset(%Invite{}, invite) |> Repo.insert
    conn = conn
      |> put_private(:test_user, user2)
      |> put_req_header("accept", "application/json")

    get conn, accept_invitation_path(conn, :accept_invitation, %{"code" => code})
    invites = Invite |> Repo.all
    assert length(invites) == 0
  end

  test "accepts invite", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    user2 = insert(:user)
    code = "ABC1234"
    level = "reader"
    invite = %{
      "project_id" => project.id,
      "code" => code,
      "level" => level,
      "email" => user2.email
    }
    Invite.changeset(%Invite{}, invite) |> Repo.insert
    conn = conn
      |> put_private(:test_user, user2)
      |> put_req_header("accept", "application/json")

    conn = get conn, accept_invitation_path(conn, :accept_invitation, %{"code" => code})
    assert json_response(conn, 200) == %{
    "data" => %{
      "project_id" => project.id,
      "level" => level
      }
    }
  end

  test "shows invite", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    code = "ABC1234"
    level = "reader"
    invite = %{
      "project_id" => project.id,
      "code" => code,
      "level" => level,
      "email" => "user@instedd.org",
      "inviter_email" => user.email
    }
    Invite.changeset(%Invite{}, invite) |> Repo.insert

    conn = get conn, invite_show_path(conn, :show, %{"code" => code})

    assert json_response(conn, 200) == %{
    "data" => %{
      "project_name" => project.name,
      "role" => level,
      "inviter_email" => user.email
      }
    }
  end
end
