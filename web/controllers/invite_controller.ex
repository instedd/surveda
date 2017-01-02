defmodule Ask.InviteController do
  use Ask.Web, :api_controller

  alias Ask.Invite

  def accept_invitation(conn, %{"code" => code}) do
    render(conn, "accept_invitation.json", %{"code": code})
  end

  def invite(conn, %{"code" => code, "level" => level, "email" => email, "project_id" => project_id}) do
    {project_id, _} = Integer.parse(project_id)

    Invite.changeset(%Invite{}, %{"code" => code, "level" => level, "email" => email, "project_id" => project_id})
    |> Repo.insert

    render(conn, "invite.json", %{project_id: project_id, code: code, email: email, level: level})
  end

end
