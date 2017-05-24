defmodule Ask.InviteController do
  use Ask.Web, :api_controller

  alias Ask.{Project, ProjectMembership, Invite, Logger}
  import Ecto.Query

  def accept_invitation(conn, %{"code" => code}) do
    invite = Repo.one(from i in Invite, where: i.code == ^code)
    if !invite do
      Logger.warn "There is no invite matching code #{inspect code}"
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

  def get_by_email_and_project(conn, %{"email" => email, "project_id" => project_id}) do
    invite = Invite |> Repo.get_by(email: email, project_id: project_id)
    if invite do
      conn
        |> put_status(:created)
        |> render("invite.json", %{project_id: invite.project_id, code: invite.code, email: invite.email, level: invite.level})
    else
      conn
      |> send_resp(:no_content, "")
    end
  end

  def invite(conn, %{"code" => code, "level" => level, "email" => email, "project_id" => project_id}) do
    project = conn
    |> load_project_for_change(project_id)

    current_user = conn |> current_user
    changeset = Invite.changeset(%Invite{}, %{"code" => code, "level" => level, "email" => email, "project_id" => project.id, "inviter_email" => current_user.email})

    case Repo.insert(changeset) do
      {:ok, _} ->
        conn
        |> put_status(:created)
        |> render("invite.json", %{project_id: project.id, code: code, email: email, level: level})
      {:error, _} ->
        invite = Repo.get_by(Invite, email: email, project_id: project_id)
        if (invite.code == code) do
          if(invite.level == level) do
            conn
              |> put_status(:created)
              |> render("invite.json", %{project_id: project.id, code: code, email: email, level: level})
          else
            changeset = invite
              |> Invite.changeset(%{"level" => level})

            case Repo.update(changeset) do
              {:ok, _} ->
                conn
                  |> put_status(:created)
                  |> render("invite.json", %{project_id: project.id, code: code, email: email, level: level})
              {:error, changeset} ->
                Logger.warn "Error when inviting collaborator #{inspect changeset}"
                conn
                  |> put_status(:unprocessable_entity)
                  |> render(Ask.ChangesetView, "error.json", changeset: changeset)
            end
          end
        else
          conn
          |> put_status(409)
          |> render("updated.json", %{email: email, code: invite.code})
        end
    end
  end

  def show(conn, %{"code" => code}) do
    invite = Invite |> Repo.get_by(code: code)
    if !invite do
      conn
      |> put_status(404)
      |> render("error.json", %{error: "invitation code is invalid", project_id: nil})
    else
      project = Project |> Repo.get(invite.project_id)
      user = conn |> current_user
      project_membership = ProjectMembership |> Repo.get_by(user_id: user.id, project_id: project.id)

      if project_membership do
        render(conn, "error.json", %{error: "The user is already a member", project_id: project.id})
      else
        render(conn, "show.json", %{project_name: project.name, inviter_email: invite.inviter_email, role: invite.level})
      end
    end
  end

  def send_invitation(conn, %{"code" => code, "level" => level, "email" => email, "project_id" => project_id}) do
    project = conn
    |> load_project_for_change(project_id)

    current_user = conn |> current_user

    recipient_user = Repo.one(from u in Ask.User, where: u.email == ^email)

    if recipient_user do
      notify_acces_to_user(conn, recipient_user, current_user, email, code, project, level)
    else
      send_invitation_email(code, level, email, project, current_user)
    end

    render(conn, "invite.json", %{project_id: project.id, code: code, email: email, level: level})
  end

  defp notify_acces_to_user(conn, recipient_user, current_user, email, code, project, level) do
    invite = Repo.one(from i in Invite, where: i.code == ^code)

    changeset = %{"user_id" => recipient_user.id, "project_id" => project.id, "level" => level}

    url = Ask.Endpoint.url <> "/projects/#{project.id}"

    Ask.Email.notify(level, email, current_user, url, project)
    |> Ask.Mailer.deliver

    Ask.Repo.transaction fn ->
      ProjectMembership.changeset(%ProjectMembership{}, changeset) |> Repo.insert
      if invite do invite |> Repo.delete! end
    end
  end

  defp send_invitation_email(code, level, email, project, current_user) do
    url = Ask.Endpoint.url <> "/confirm?code=#{code}"

    Ask.Email.invite(level, email, current_user, url, project)
    |> Ask.Mailer.deliver

    Invite.changeset(%Invite{}, %{"code" => code, "level" => level, "email" => email, "project_id" => project.id, "inviter_email" => current_user.email})
    |> Repo.insert
  end
end
