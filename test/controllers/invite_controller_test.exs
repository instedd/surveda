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
    email = "user@instedd.org"
    get conn, invite_path(conn, :invite, %{"code" => code, "level" => level, "email" => email, "project_id" => project.id})
    invite = Invite |> last |> Repo.one
    assert(invite.level == level && invite.code == code && invite.project_id == project.id && invite.email == email)
  end

  test "forbids user outside a project to invite", %{conn: conn} do
    project = insert(:project)
    code = "ABC1234"
    level = "reader"
    email = "user@instedd.org"
    assert_error_sent :forbidden, fn ->
      get conn, invite_path(conn, :invite, %{"code" => code, "level" => level, "email" => email, "project_id" => project.id})
    end
  end

  test "forbids reader to invite", %{conn: conn, user: user} do
    project = create_project_for_user(user, level: "reader")
    code = "ABC1234"
    level = "reader"
    email = "user@instedd.org"
    assert_error_sent :forbidden, fn ->
      get conn, invite_path(conn, :invite, %{"code" => code, "level" => level, "email" => email, "project_id" => project.id})
    end
  end

  test "forbids user to invite if project is archived", %{conn: conn, user: user} do
    project = create_project_for_user(user, archived: true)
    code = "ABC1234"
    level = "reader"
    email = "user@instedd.org"
    assert_error_sent :forbidden, fn ->
      get conn, invite_path(conn, :invite, %{"code" => code, "level" => level, "email" => email, "project_id" => project.id})
    end
  end

  test "forbids owner to invite with owner permissions", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    code = "ABC1234"
    level = "owner"
    email = "user@instedd.org"
    assert_error_sent :forbidden, fn ->
      get conn, invite_path(conn, :invite, %{"code" => code, "level" => level, "email" => email, "project_id" => project.id})
    end
  end

  test "forbids admin to invite with owner permissions", %{conn: conn, user: user} do
    project = create_project_for_user(user, level: "admin")
    code = "ABC1234"
    level = "owner"
    email = "user@instedd.org"
    assert_error_sent :forbidden, fn ->
      get conn, invite_path(conn, :invite, %{"code" => code, "level" => level, "email" => email, "project_id" => project.id})
    end
  end

  test "forbids editor to invite with admin permissions", %{conn: conn, user: user} do
    project = create_project_for_user(user, level: "editor")
    code = "ABC1234"
    level = "admin"
    email = "user@instedd.org"
    assert_error_sent :forbidden, fn ->
      get conn, invite_path(conn, :invite, %{"code" => code, "level" => level, "email" => email, "project_id" => project.id})
    end
  end

  test "allows admin to invite", %{conn: conn, user: user} do
    project = create_project_for_user(user, level: "admin")
    code = "ABC1234"
    level = "admin"
    email = "user@instedd.org"
    conn = get conn, invite_path(conn, :invite, %{"code" => code, "level" => level, "email" => email, "project_id" => project.id})
    assert json_response(conn, 201) == %{
      "data" => %{
        "project_id" => project.id,
        "code" => code,
        "level" => level,
        "email" => email
      }
    }
  end

  test "invites user as reader", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    code = "ABC1234"
    level = "reader"
    email = "user@instedd.org"
    conn = get conn, invite_path(conn, :invite, %{"code" => code, "level" => level, "email" => email, "project_id" => project.id})
    assert json_response(conn, 201) == %{
      "data" => %{
        "project_id" => project.id,
        "code" => code,
        "level" => level,
        "email" => email
      }
    }
  end

  test "invites user as editor", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    code = "ABC1234"
    level = "editor"
    email = "user@instedd.org"
    conn = get conn, invite_path(conn, :invite, %{"code" => code, "level" => level, "email" => email, "project_id" => project.id})
    assert json_response(conn, 201) == %{
      "data" => %{
        "project_id" => project.id,
        "code" => code,
        "level" => level,
        "email" => email
      }
    }
  end

  test "invites user as admin", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    code = "ABC1234"
    level = "admin"
    email = "user@instedd.org"
    conn = get conn, invite_path(conn, :invite, %{"code" => code, "level" => level, "email" => email, "project_id" => project.id})
    assert json_response(conn, 201) == %{
      "data" => %{
        "project_id" => project.id,
        "code" => code,
        "level" => level,
        "email" => email
      }
    }
  end

  test "if an invite already exists and the same code is sent, it is updated with the new level", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    code = "ABC1234"
    level = "reader"
    email = "user@instedd.org"
    get conn, invite_path(conn, :invite, %{"code" => code, "level" => level, "email" => email, "project_id" => project.id})

    conn = get conn, invite_path(conn, :invite, %{"code" => code, "level" => "editor", "email" => email, "project_id" => project.id})

    assert json_response(conn, 201) == %{
      "data" => %{
        "project_id" => project.id,
        "code" => code,
        "level" => "editor",
        "email" => email
      }
    }
  end

  test "if an invite already exists and the same code is sent, but the new level is owner it returns error", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    code = "ABC1234"
    level = "editor"
    email = "user@instedd.org"
    get conn, invite_path(conn, :invite, %{"code" => code, "level" => level, "email" => email, "project_id" => project.id})

    assert_error_sent :forbidden, fn ->
      get conn, invite_path(conn, :invite, %{"code" => code, "level" => "owner", "email" => email, "project_id" => project.id})
    end
  end

  test "if an invite already exists and a different code is sent, it returns conflict", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    code = "ABC1234"
    code2 = "ABC1235"
    level = "reader"
    email = "user@instedd.org"
    get conn, invite_path(conn, :invite, %{"code" => code, "level" => level, "email" => email, "project_id" => project.id})

    conn = get conn, invite_path(conn, :invite, %{"code" => code2, "level" => "editor", "email" => email, "project_id" => project.id})

    assert json_response(conn, 409) == %{
      "data" => %{
        "code" => code,
        "email" => email
      }
    }
  end

  test "creates membership when accepting invite", %{conn: conn, user: user} do
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

  test "shows invite", %{conn: conn} do
    user2 = insert(:user)
    project = create_project_for_user(user2)
    code = "ABC1234"
    level = "reader"
    invite = %{
      "project_id" => project.id,
      "code" => code,
      "level" => level,
      "email" => "user@instedd.org",
      "inviter_email" => user2.email
    }
    Invite.changeset(%Invite{}, invite) |> Repo.insert

    conn = get conn, invite_show_path(conn, :show, %{"code" => code})

    assert json_response(conn, 200) == %{
    "data" => %{
      "project_name" => project.name,
      "role" => level,
      "inviter_email" => user2.email
      }
    }
  end

  test "returns error when the user is already a member", %{conn: conn, user: user} do
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
      "error" => "The user is already a member",
      "project_id" => project.id
      }
    }
  end

  test "updates invite", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    code = "ABC1234"
    email = "user@instedd.org"
    invite = %{
      "project_id" => project.id,
      "code" => code,
      "level" => "reader",
      "email" => email,
      "inviter_email" => user.email
    }
    Invite.changeset(%Invite{}, invite) |> Repo.insert

    put conn, invite_update_path(conn, :update, %{"project_id" => project.id, "email" => email, "level" => "editor"})

    updated_invite = Repo.one(from i in Invite, where: i.project_id == ^project.id and i.email == ^email)
    assert updated_invite.level == "editor"
  end

  test "updates invite from reader to admin when the user is owner", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    code = "ABC1234"
    email = "user@instedd.org"
    invite = %{
      "project_id" => project.id,
      "code" => code,
      "level" => "reader",
      "email" => email,
      "inviter_email" => user.email
    }
    Invite.changeset(%Invite{}, invite) |> Repo.insert

    put conn, invite_update_path(conn, :update, %{"project_id" => project.id, "email" => email, "level" => "admin"})

    updated_invite = Repo.one(from i in Invite, where: i.project_id == ^project.id and i.email == ^email)
    assert updated_invite.level == "admin"
  end

  test "updates invite from editor to admin when the user is admin", %{conn: conn, user: user} do
    project = create_project_for_user(user, level: "admin")
    code = "ABC1234"
    email = "user@instedd.org"
    invite = %{
      "project_id" => project.id,
      "code" => code,
      "level" => "editor",
      "email" => email,
      "inviter_email" => user.email
    }
    Invite.changeset(%Invite{}, invite) |> Repo.insert

    put conn, invite_update_path(conn, :update, %{"project_id" => project.id, "email" => email, "level" => "admin"})

    updated_invite = Repo.one(from i in Invite, where: i.project_id == ^project.id and i.email == ^email)
    assert updated_invite.level == "admin"
  end

  test "forbids user outside a project to update", %{conn: conn, user: user} do
    project = insert(:project)
    code = "ABC1234"
    email = "user@instedd.org"
    invite = %{
      "project_id" => project.id,
      "code" => code,
      "level" => "reader",
      "email" => email,
      "inviter_email" => user.email
    }
    Invite.changeset(%Invite{}, invite) |> Repo.insert

    assert_error_sent :forbidden, fn ->
      put conn, invite_update_path(conn, :update, %{"project_id" => project.id, "email" => email, "level" => "editor"})
    end
  end

  test "forbids owner to update to owner", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    code = "ABC1234"
    email = "user@instedd.org"
    invite = %{
      "project_id" => project.id,
      "code" => code,
      "level" => "editor",
      "email" => email,
      "inviter_email" => user.email
    }
    Invite.changeset(%Invite{}, invite) |> Repo.insert

    assert_error_sent :forbidden, fn ->
      put conn, invite_update_path(conn, :update, %{"project_id" => project.id, "email" => email, "level" => "owner"})
    end
  end

  test "forbids admin to update to owner", %{conn: conn, user: user} do
    project = create_project_for_user(user, level: "admin")
    code = "ABC1234"
    email = "user@instedd.org"
    invite = %{
      "project_id" => project.id,
      "code" => code,
      "level" => "editor",
      "email" => email,
      "inviter_email" => user.email
    }
    Invite.changeset(%Invite{}, invite) |> Repo.insert

    assert_error_sent :forbidden, fn ->
      put conn, invite_update_path(conn, :update, %{"project_id" => project.id, "email" => email, "level" => "owner"})
    end
  end

  test "forbids editor to update to admin", %{conn: conn, user: user} do
    project = create_project_for_user(user, level: "editor")
    code = "ABC1234"
    email = "user@instedd.org"
    invite = %{
      "project_id" => project.id,
      "code" => code,
      "level" => "reader",
      "email" => email,
      "inviter_email" => user.email
    }
    Invite.changeset(%Invite{}, invite) |> Repo.insert

    assert_error_sent :forbidden, fn ->
      put conn, invite_update_path(conn, :update, %{"project_id" => project.id, "email" => email, "level" => "admin"})
    end
  end

  test "forbids reader to update", %{conn: conn, user: user} do
    project = create_project_for_user(user, level: "reader")
    code = "ABC1234"
    email = "user@instedd.org"
    invite = %{
      "project_id" => project.id,
      "code" => code,
      "level" => "reader",
      "email" => email,
      "inviter_email" => user.email
    }
    Invite.changeset(%Invite{}, invite) |> Repo.insert

    assert_error_sent :forbidden, fn ->
      put conn, invite_update_path(conn, :update, %{"project_id" => project.id, "email" => email, "level" => "editor"})
    end
  end

  test "forbids user to update if project is archived", %{conn: conn, user: user} do
    project = create_project_for_user(user, archived: true)
    code = "ABC1234"
    email = "user@instedd.org"
    invite = %{
      "project_id" => project.id,
      "code" => code,
      "level" => "reader",
      "email" => email,
      "inviter_email" => user.email
    }
    Invite.changeset(%Invite{}, invite) |> Repo.insert

    assert_error_sent :forbidden, fn ->
      put conn, invite_update_path(conn, :update, %{"project_id" => project.id, "email" => email, "level" => "editor"})
    end
  end


  test "removes invite", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    code = "ABC1234"
    email = "user@instedd.org"
    invite = %{
      "project_id" => project.id,
      "code" => code,
      "level" => "reader",
      "email" => email,
      "inviter_email" => user.email
    }
    Invite.changeset(%Invite{}, invite) |> Repo.insert

    delete conn, invite_remove_path(conn, :remove, %{"project_id" => project.id, "email" => email})

    assert Repo.one(from i in Invite, where: i.email == ^email and i.project_id == ^project.id) == nil
  end

  test "forbids reader to remove invite", %{conn: conn, user: user} do
    project = create_project_for_user(user, level: "reader")
    code = "ABC1234"
    email = "user@instedd.org"
    invite = %{
      "project_id" => project.id,
      "code" => code,
      "level" => "reader",
      "email" => email,
      "inviter_email" => user.email
    }
    Invite.changeset(%Invite{}, invite) |> Repo.insert

    assert_error_sent :forbidden, fn ->
      delete conn, invite_remove_path(conn, :remove, %{"project_id" => project.id, "email" => email})
    end
  end

  test "forbids user outside a project to remove invite", %{conn: conn, user: user} do
    project = insert(:project)
    code = "ABC1234"
    email = "user@instedd.org"
    invite = %{
      "project_id" => project.id,
      "code" => code,
      "level" => "reader",
      "email" => email,
      "inviter_email" => user.email
    }
    Invite.changeset(%Invite{}, invite) |> Repo.insert

    assert_error_sent :forbidden, fn ->
      delete conn, invite_remove_path(conn, :remove, %{"project_id" => project.id, "email" => email})
    end
  end

  test "forbids user to remove invite if project is archived", %{conn: conn, user: user} do
    project = create_project_for_user(user, archived: true)
    code = "ABC1234"
    email = "user@instedd.org"
    invite = %{
      "project_id" => project.id,
      "code" => code,
      "level" => "reader",
      "email" => email,
      "inviter_email" => user.email
    }
    Invite.changeset(%Invite{}, invite) |> Repo.insert

    assert_error_sent :forbidden, fn ->
      delete conn, invite_remove_path(conn, :remove, %{"project_id" => project.id, "email" => email})
    end
  end

end
