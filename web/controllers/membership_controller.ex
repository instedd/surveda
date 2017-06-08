defmodule Ask.MembershipController do
  use Ask.Web, :api_controller

  alias Ask.{Project, ProjectMembership, User}

  def remove(conn, params) do
    project_id = params["project_id"]
    user_id = Repo.one(from u in User, where: u.email == ^params["email"], select: u.id)

    conn
    |> load_project_for_change(project_id)

    membership = Project
    |> Repo.get!(project_id)
    |> assoc(:project_memberships)
    |> where([m], m.user_id == ^user_id)
    |> Repo.one

    membership
    |> Repo.delete!()

    send_resp(conn, :no_content, "")
  end

  def update(conn, params) do
    project_id = params["project_id"]
    user_id = params["user_id"]
    new_level = params["new_level"]

    Repo.one(from m in ProjectMembership, where: m.user_id == ^user_id and m.project_id == ^project_id)
    |> ProjectMembership.changeset(%{level: new_level})
    |> Repo.update

    send_resp(conn, :no_content, "")
  end
end
