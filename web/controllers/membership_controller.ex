defmodule Ask.MembershipController do
  use Ask.Web, :api_controller

  alias Ask.{ProjectMembership, User, UnauthorizedError, ActivityLog}

  def remove(conn, %{"project_id" => project_id, "email" => email}) do
    conn
    |> load_project_for_change(project_id)

    user = Repo.one(from u in User, where: u.email == ^email)

    project_membership = ProjectMembership
    |> where([pm], pm.user_id == ^user.id and pm.project_id == ^project_id)
    |> preload(:project)
    |> Repo.one
    |> check_target_collaborator_is_not_owner(conn)

    activity_log_metadata = %{
      project_name: project_membership.project.name,
      collaborator_email: email,
      collaborator_name: user.name
    }

    activity_log_props = %{
      project_id: project_id, user_id: current_user(conn).id, entity_id: project_id, entity_type: "project", action: "remove_collaborator", metadata: activity_log_metadata
    }

    Repo.transaction fn ->
      project_membership
      |> Repo.delete!()

      ActivityLog.create(activity_log_props)
    end

    send_resp(conn, :no_content, "")
  end

  def update(conn, %{"level" => "owner"}) do
    raise UnauthorizedError, conn: conn
  end

  def update(conn, %{"project_id" => project_id, "level" => "admin", "email" => email}) do
    conn
    |> load_project_for_owner(project_id)

    perform_update(conn, project_id, "admin", email)
  end

  def update(conn, %{"project_id" => project_id, "level" => new_level, "email" => email}) do
    conn
    |> load_project_for_change(project_id)

    perform_update(conn, project_id, new_level, email)
  end

  def perform_update(conn, project_id, new_level, email) do
    user = Repo.one(from u in User, where: u.email == ^email)
    project_membership = ProjectMembership
                          |> where([pm], pm.user_id == ^user.id and pm.project_id == ^project_id)
                          |> preload(:project)
                          |> Repo.one

    activity_log_metadata = %{
      project_name: project_membership.project.name,
      collaborator_email: email,
      collaborator_name: user.name,
      old_role: project_membership.level,
      new_role: new_level
    }

    activity_log_props = %{
      project_id: project_id, user_id: current_user(conn).id, entity_id: project_id, entity_type: "project", action: "edit_collaborator", metadata: activity_log_metadata
    }

    Repo.transaction fn ->
      project_membership
      |> check_target_collaborator_is_not_owner(conn)
      |> ProjectMembership.changeset(%{level: new_level})
      |> Repo.update

      ActivityLog.create(activity_log_props)
    end

    send_resp(conn, :no_content, "")
  end

end
