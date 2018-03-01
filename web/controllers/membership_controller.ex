defmodule Ask.MembershipController do
  use Ask.Web, :api_controller

  alias Ask.{Project, ProjectMembership, User, UnauthorizedError}

  def remove(conn, %{"project_id" => project_id, "email" => email}) do
    user_id = Repo.one(from u in User, where: u.email == ^email, select: u.id)

    conn
    |> load_project_for_change(project_id)

    membership = Project
    |> Repo.get!(project_id)
    |> assoc(:project_memberships)
    |> where([m], m.user_id == ^user_id)
    |> Repo.one
    |> check_target_collaborator_is_not_owner(conn)

    membership
    |> Repo.delete!()

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
    user_id = Repo.one(from u in User, where: u.email == ^email, select: u.id)

    Repo.one(from m in ProjectMembership, where: m.user_id == ^user_id and m.project_id == ^project_id)
    |> check_target_collaborator_is_not_owner(conn)
    |> ProjectMembership.changeset(%{level: new_level})
    |> Repo.update

    send_resp(conn, :no_content, "")
  end

end
