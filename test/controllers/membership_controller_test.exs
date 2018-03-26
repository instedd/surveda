defmodule Ask.MembershipControllerTest do

  import Ecto.Query

  use Ask.ConnCase
  use Ask.TestHelpers

  alias Ask.{ProjectMembership, ActivityLog}

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

  test "forbids user to remove if project is archived", %{conn: conn, user: user} do
    project = create_project_for_user(user, archived: true)
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

  test "generates log after removing membership", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    collaborator_email = "user2@surveda.instedd.org"
    collaborator = insert(:user, name: "user2", email: collaborator_email)
    collaborator_membership = %{"user_id" => collaborator.id, "project_id" => project.id, "level" => "editor"}
    ProjectMembership.changeset(%ProjectMembership{}, collaborator_membership) |> Repo.insert
    remote_ip = {192, 168, 0, 128}
    remote_ip_string = "192.168.0.128"
    conn = conn |> Map.put(:remote_ip, remote_ip)

    delete conn, project_membership_remove_path(conn, :remove, project.id), email: collaborator_email

    activity_log = ActivityLog |> Repo.one
    assert activity_log.project_id == project.id
    assert activity_log.user_id == user.id
    assert activity_log.entity_id == project.id
    assert activity_log.entity_type == "project"
    assert activity_log.action == "remove_collaborator"
    assert activity_log.remote_ip == remote_ip_string

    assert activity_log.metadata == %{
      "project_name" => project.name,
      "collaborator_email" => collaborator_email,
      "collaborator_name" => collaborator.name,
      "role" => "editor"
    }
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

  test "does not change level to an invalid value", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    collaborator_email = "user2@surveda.instedd.org"
    collaborator = insert(:user, name: "user2", email: collaborator_email)
    collaborator_membership = %{"user_id" => collaborator.id, "project_id" => project.id, "level" => "editor"}
    ProjectMembership.changeset(%ProjectMembership{}, collaborator_membership) |> Repo.insert

    conn = put conn, project_membership_update_path(conn, :update, project.id), email: collaborator_email, level: "invalid"
    updated_membership = Repo.one(from p in ProjectMembership, where: p.user_id == ^collaborator.id)
    assert conn.status == 422
    assert updated_membership.level == "editor"
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

  test "forbids user to update if project is archived", %{conn: conn, user: user} do
    project = create_project_for_user(user, archived: true)
    collaborator_email = "user2@surveda.instedd.org"
    collaborator = insert(:user, name: "user2", email: collaborator_email)
    collaborator_membership = %{"user_id" => collaborator.id, "project_id" => project.id, "level" => "editor"}
    ProjectMembership.changeset(%ProjectMembership{}, collaborator_membership) |> Repo.insert

    assert_error_sent :forbidden, fn ->
      put conn, project_membership_update_path(conn, :update, project.id), email: collaborator_email, level: "reader"
    end
  end

  test "generates log after updating membership", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    collaborator_email = "user2@surveda.instedd.org"
    collaborator = insert(:user, name: "user2", email: collaborator_email)
    collaborator_membership = %{"user_id" => collaborator.id, "project_id" => project.id, "level" => "editor"}
    ProjectMembership.changeset(%ProjectMembership{}, collaborator_membership) |> Repo.insert
    remote_ip = {192, 168, 0, 128}
    remote_ip_string = "192.168.0.128"
    conn = conn |> Map.put(:remote_ip, remote_ip)

    put conn, project_membership_update_path(conn, :update, project.id), email: collaborator_email, level: "reader"

    activity_log = ActivityLog |> Repo.one
    assert activity_log.project_id == project.id
    assert activity_log.user_id == user.id
    assert activity_log.entity_id == project.id
    assert activity_log.entity_type == "project"
    assert activity_log.action == "edit_collaborator"
    assert activity_log.remote_ip == remote_ip_string

    assert activity_log.metadata == %{
      "project_name" => project.name,
      "collaborator_email" => collaborator_email,
      "collaborator_name" => collaborator.name,
      "old_role" => "editor",
      "new_role" => "reader"
    }
  end

end
