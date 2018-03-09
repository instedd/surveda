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
    |> check_target_collaborator_is_not_owner()

    membership
    |> Repo.delete!()

    send_resp(conn, :no_content, "")
  end

  def update(_, %{"level" => "owner"}) do
    raise UnauthorizedError
  end

  def update(conn, %{"project_id" => project_id, "level" => new_level, "email" => email}) do
    user_id = Repo.one(from u in User, where: u.email == ^email, select: u.id)

    Repo.one(from m in ProjectMembership, where: m.user_id == ^user_id and m.project_id == ^project_id)
    |> check_target_collaborator_is_not_owner()
    |> ProjectMembership.changeset(%{level: new_level})
    |> ProjectMembership.authorize(user_level(project_id, current_user(conn).id))
    |> Repo.update!

    send_resp(conn, :no_content, "")
  end

end
