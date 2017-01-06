defmodule Ask.InviteController do
  use Ask.Web, :api_controller

  alias Ask.{Project, ProjectMembership, Invite}
  import Ecto.Query

  def accept_invitation(conn, %{"code" => code}) do
    invite = Repo.one(from i in Invite, where: i.code == ^code)
    if !invite do
      render(conn, "error.json", error: "invitation code is invalid")
    else
      user = conn |> current_user
      changeset = %{"user_id" => user.id, "project_id" => invite.project_id, "level" => invite.level}
      Ask.Repo.transaction fn ->
        ProjectMembership.changeset(%ProjectMembership{}, changeset) |> Repo.insert
        invite |> Repo.delete!
      end
      render(conn, "accept_invitation.json", %{"level": invite.level, "project_id": invite.project_id})
    end
  end

  def invite(conn, %{"code" => code, "level" => level, "email" => email, "project_id" => project_id}) do
    {project_id, _} = Integer.parse(project_id)

    current_user = conn |> current_user
    Invite.changeset(%Invite{}, %{"code" => code, "level" => level, "email" => email, "project_id" => project_id, "inviter_email" => current_user.email})
    |> Repo.insert

    render(conn, "invite.json", %{project_id: project_id, code: code, email: email, level: level})
  end

  def show(conn, %{"code" => code}) do
    invite = Invite |> Repo.get_by(code: code)
    project = Project |> Repo.get(invite.project_id)
    render(conn, "show.json", %{project_name: project.name, inviter_email: invite.inviter_email, role: invite.level})
  end

  def invite_mail(conn, %{"code" => code, "level" => level, "email" => email, "project_id" => project_id}) do
    {project_id, _} = Integer.parse(project_id)

    url = Ask.Endpoint.url <> "/confirm?code=#{code}"
    current_user = conn |> current_user

    %Bamboo.Email{
      from: "noreply@instedd.org",
      to: email,
      subject: "Accept invitation",
      text_body: "You have been invited to collaborate. Follow this link: #{url}",
      headers: %{}
    } |> Ask.Mailer.deliver_now


    Invite.changeset(%Invite{}, %{"code" => code, "level" => level, "email" => email, "project_id" => project_id, "inviter_email" => current_user.email})
    |> Repo.insert

    render(conn, "invite.json", %{project_id: project_id, code: code, email: email, level: level})
  end

end
