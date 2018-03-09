defmodule Ask.MembershipControllerTest do

  import Ecto.Query

  use Ask.ConnCase
  use Ask.TestHelpers

  alias Ask.{ProjectMembership}

  setup %{conn: conn} do
    user = insert(:user)
    conn = conn
      |> put_private(:test_user, user)
      |> put_req_header("accept", "application/json")

    {:ok, conn: conn, user: user}
  end

  test "removes member", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    collaborator_email = "user2@surveda.instedd.org"
    collaborator = insert(:user, name: "user2", email: collaborator_email)
    collaborator_membership = %{"user_id" => collaborator.id, "project_id" => project.id, "level" => "editor"}
    ProjectMembership.changeset(%ProjectMembership{}, collaborator_membership) |> Repo.insert

    delete conn, project_membership_remove_path(conn, :remove, project.id), email: collaborator_email
    ProjectMembership |> Repo.all |> Repo.preload(:user)

    assert !(ProjectMembership |> Repo.all |> Enum.any?( fn pm -> pm.user_id == collaborator.id end ))
  end

  test "forbids reader to remove", %{conn: conn, user: user} do
    project = create_project_for_user(user, level: "reader")
    collaborator_email = "user2@surveda.instedd.org"
    collaborator = insert(:user, name: "user2", email: collaborator_email)
    collaborator_membership = %{"user_id" => collaborator.id, "project_id" => project.id, "level" => "editor"}
    ProjectMembership.changeset(%ProjectMembership{}, collaborator_membership) |> Repo.insert

    assert_error_sent :forbidden, fn ->
      delete conn, project_membership_remove_path(conn, :remove, project.id), email: collaborator_email
    end
  end

  test "forbids user outside a project to remove", %{conn: conn} do
    project = insert(:project)
    collaborator_email = "user2@surveda.instedd.org"
    collaborator = insert(:user, name: "user2", email: collaborator_email)
    collaborator_membership = %{"user_id" => collaborator.id, "project_id" => project.id, "level" => "editor"}
    ProjectMembership.changeset(%ProjectMembership{}, collaborator_membership) |> Repo.insert

    assert_error_sent :forbidden, fn ->
      delete conn, project_membership_remove_path(conn, :remove, project.id), email: collaborator_email
    end
  end

  test "forbids user to remove owner", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    collaborator_email = "user2@surveda.instedd.org"
    collaborator = insert(:user, name: "user2", email: collaborator_email)
    collaborator_membership = %{"user_id" => collaborator.id, "project_id" => project.id, "level" => "owner"}
    ProjectMembership.changeset(%ProjectMembership{}, collaborator_membership) |> Repo.insert

    assert_error_sent :forbidden, fn ->
      delete conn, project_membership_remove_path(conn, :remove, project.id), email: collaborator_email
    end
  end

  test "updates member's level", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    collaborator_email = "user2@surveda.instedd.org"
    collaborator = insert(:user, name: "user2", email: collaborator_email)
    collaborator_membership = %{"user_id" => collaborator.id, "project_id" => project.id, "level" => "editor"}
    ProjectMembership.changeset(%ProjectMembership{}, collaborator_membership) |> Repo.insert

    put conn, project_membership_update_path(conn, :update, project.id), email: collaborator_email, level: "reader"

    updated_membership = Repo.one(from p in ProjectMembership, where: p.user_id == ^collaborator.id)
    assert updated_membership.level == "reader"
  end

  test "forbids user to update owner", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    collaborator_email = "user2@surveda.instedd.org"
    collaborator = insert(:user, name: "user2", email: collaborator_email)
    collaborator_membership = %{"user_id" => collaborator.id, "project_id" => project.id, "level" => "owner"}
    ProjectMembership.changeset(%ProjectMembership{}, collaborator_membership) |> Repo.insert

    assert_error_sent :forbidden, fn ->
      put conn, project_membership_update_path(conn, :update, project.id), email: collaborator_email, level: "reader"
    end
  end

  test "forbids editor to upgrade other to owner", %{conn: conn, user: user} do
    collaborator_email = "user2@surveda.instedd.org"
    collaborator = insert(:user, name: "user2", email: collaborator_email)

    project = create_project_for_user(collaborator)

    user_membership = %{"user_id" => user.id, "project_id" => project.id, "level" => "editor"}
    ProjectMembership.changeset(%ProjectMembership{}, user_membership) |> Repo.insert

    assert_error_sent :forbidden, fn ->
      put conn, project_membership_update_path(conn, :update, project.id), email: user.email, level: "owner"
    end
  end

  test "forbids reader to upgrade other to editor", %{conn: conn, user: user} do
    collaborator_email = "user2@surveda.instedd.org"
    collaborator = insert(:user, name: "user2", email: collaborator_email)

    project = create_project_for_user(collaborator)

    user_membership = %{"user_id" => user.id, "project_id" => project.id, "level" => "reader"}
    ProjectMembership.changeset(%ProjectMembership{}, user_membership) |> Repo.insert

    assert_error_sent :forbidden, fn ->
      put conn, project_membership_update_path(conn, :update, project.id), email: user.email, level: "editor"
    end
  end

  test "forbids editor to update to admin", %{conn: conn, user: user} do
    project = create_project_for_user(user, level: "editor")
    collaborator_email = "user2@surveda.instedd.org"
    collaborator = insert(:user, name: "user2", email: collaborator_email)
    collaborator_membership = %{"user_id" => collaborator.id, "project_id" => project.id, "level" => "admin"}
    ProjectMembership.changeset(%ProjectMembership{}, collaborator_membership) |> Repo.insert

    assert_error_sent :forbidden, fn ->
      put conn, project_membership_update_path(conn, :update, project.id), email: collaborator_email, level: "admin"
    end
  end

  test "forbids editor to downgrade an admin to editor", %{conn: conn, user: user} do
    project = create_project_for_user(user, level: "editor")
    collaborator_email = "user2@surveda.instedd.org"
    collaborator = insert(:user, name: "user2", email: collaborator_email)
    collaborator_membership = %{"user_id" => collaborator.id, "project_id" => project.id, "level" => "admin"}
    ProjectMembership.changeset(%ProjectMembership{}, collaborator_membership) |> Repo.insert

    assert_error_sent :forbidden, fn ->
      put conn, project_membership_update_path(conn, :update, project.id), email: collaborator_email, level: "editor"
    end
  end

  test "forbids reader to update", %{conn: conn, user: user} do
    project = create_project_for_user(user, level: "reader")
    collaborator_email = "user2@surveda.instedd.org"
    collaborator = insert(:user, name: "user2", email: collaborator_email)
    collaborator_membership = %{"user_id" => collaborator.id, "project_id" => project.id, "level" => "editor"}
    ProjectMembership.changeset(%ProjectMembership{}, collaborator_membership) |> Repo.insert

    assert_error_sent :forbidden, fn ->
      put conn, project_membership_update_path(conn, :update, project.id), email: collaborator_email, level: "reader"
    end
  end

  test "forbids user outside a project to update", %{conn: conn} do
    project = insert(:project)
    collaborator_email = "user2@surveda.instedd.org"
    collaborator = insert(:user, name: "user2", email: collaborator_email)
    collaborator_membership = %{"user_id" => collaborator.id, "project_id" => project.id, "level" => "editor"}
    ProjectMembership.changeset(%ProjectMembership{}, collaborator_membership) |> Repo.insert

    assert_error_sent :forbidden, fn ->
      put conn, project_membership_update_path(conn, :update, project.id), email: collaborator_email, level: "reader"
    end
  end

end
