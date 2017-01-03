defmodule Ask.InviteController do
  use Ask.Web, :api_controller

  alias Ask.{ProjectMembership, Invite}
  import Ecto.Query

  def accept_invitation(conn, %{"code" => code}) do
    invite = Repo.one(from i in Invite, where: i.code == ^code)
    user = conn |> current_user
    changeset = %{"user_id" => user.id, "project_id" => invite.project_id, "level" => invite.level}
    ProjectMembership.changeset(%ProjectMembership{}, changeset) |> Repo.insert
    render(conn, "accept_invitation.json", %{"level": invite.level, "project_id": invite.project_id})
  end

  def invite(conn, %{"code" => code, "level" => level, "email" => email, "project_id" => project_id}) do
    {project_id, _} = Integer.parse(project_id)

    Invite.changeset(%Invite{}, %{"code" => code, "level" => level, "email" => email, "project_id" => project_id})
    |> Repo.insert

    render(conn, "invite.json", %{project_id: project_id, code: code, email: email, level: level})
  end

end
