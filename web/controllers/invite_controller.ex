defmodule Ask.InviteController do
  use Ask.Web, :api_controller

  alias Ask.{Project, ProjectMembership, Invite, Logger, UnauthorizedError, ActivityLog}
  alias Ecto.Multi
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
      render(conn, "accept_invitation.json", %{level: invite.level, project_id: invite.project_id})
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

  def invite(_, %{"level" => "owner"}) do
    raise UnauthorizedError
  end

  def invite(conn, %{"code" => code, "level" => "admin", "email" => email, "project_id" => project_id}) do
    project = conn
      |> load_project_for_owner(project_id)

    perform_invite(conn, project, code, "admin", email, project_id)
  end

  def invite(conn, %{"code" => code, "level" => level, "email" => email, "project_id" => project_id}) do
    project = conn
    |> load_project_for_change(project_id)

    perform_invite(conn, project, code, level, email, project_id)
  end

  def perform_invite(conn, project, code, level, email, project_id) do
    current_user = conn |> current_user
    changeset = Invite.changeset(%Invite{}, %{"code" => code, "level" => level, "email" => email, "project_id" => project.id, "inviter_email" => current_user.email})

    insert_multi = Multi.new()
    |> Multi.insert(:insert_invite, changeset)
    |> Multi.insert(:insert_log, ActivityLog.create_invite(project, conn, email, level))
    |> Repo.transaction

    case insert_multi do
      {:ok, _} ->
        conn
        |> put_status(:created)
        |> render("invite.json", %{project_id: project.id, code: code, email: email, level: level})
      {:error, :insert_invite, _, _} ->
        invite = Repo.get_by(Invite, email: email, project_id: project_id)
        if (invite.code == code) do
          if(invite.level == level) do
            conn
              |> put_status(:created)
              |> render("invite.json", %{project_id: project.id, code: code, email: email, level: level})
          else
            changeset = invite
              |> Invite.changeset(%{"level" => level})

            update_multi = Multi.new()
            |> Multi.update(:update_invite, changeset)
            |> Multi.insert(:insert_log, ActivityLog.edit_invite(project, conn, email, invite.level, level))
            |> Repo.transaction

            case update_multi do
              {:ok, _} ->
                conn
                  |> put_status(:created)
                  |> render("invite.json", %{project_id: project.id, code: code, email: email, level: level})
              {:error, _, _, _} ->
                Logger.warn "Error when inviting collaborator #{inspect changeset}"
                conn
                  |> put_status(:unprocessable_entity)
                  |> put_view(Ask.ChangesetView)
                  |> render("error.json", changeset: changeset)
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
      notify_access_to_user(conn, recipient_user, current_user, email, code, project, level)
    else
      send_invitation_email(code, level, email, project, conn)
    end

    render(conn, "invite.json", %{project_id: project.id, code: code, email: email, level: level})
  end

  def update(_, %{"level" => "owner"}) do
    raise UnauthorizedError
  end

  def update(conn, %{"email" => email, "project_id" => project_id, "level" => "admin"}) do
    project = conn
              |> load_project_for_owner(project_id)
    perform_update(conn, email, project, "admin")
  end

  def update(conn, %{"email" => email, "project_id" => project_id, "level" => new_level}) do
    project = conn
              |> load_project_for_change(project_id)

    perform_update(conn, email, project, new_level)
  end

  def perform_update(conn, email, project, new_level) do
    invite = Repo.one(from i in Invite, where: i.email == ^email and i.project_id == ^project.id)

    multi = Multi.new
    |> Multi.update(:update, Invite.changeset(invite, %{level: new_level}))
    |> Multi.insert(:insert, ActivityLog.edit_invite(project, conn, email, invite.level, new_level))
    |> Repo.transaction

    case multi do
      {:ok, _} ->
        send_resp(conn, :no_content, "")
      {:error, _, error_changeset, _} ->
        conn
          |> put_status(:unprocessable_entity)
          |> put_view(Ask.ChangesetView)
          |> render("error.json", changeset: error_changeset)
    end
  end

  def remove(conn, %{"email" => email, "project_id" => project_id}) do
    project = conn
    |> load_project_for_change(project_id)

    invite = Repo.one(from i in Invite, where: i.email == ^email and i.project_id == ^project_id)

    multi = Multi.new
    |> Multi.delete(:delete, invite)
    |> Multi.insert(:insert, ActivityLog.delete_invite(project, conn, email, invite.level))
    |> Repo.transaction

    case multi do
      {:ok, _} ->
        send_resp(conn, :no_content, "")
      {:error, _, error_changeset, _} ->
        conn
          |> put_status(:unprocessable_entity)
          |> put_view(Ask.ChangesetView)
          |> render("error.json", changeset: error_changeset)
    end
  end

  defp notify_access_to_user(_, recipient_user, current_user, email, code, project, level) do
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

  defp send_invitation_email(code, level, email, project, conn) do
    url = Ask.Endpoint.url <> "/confirm?code=#{code}"
    current_user = current_user(conn)

    Ask.Email.invite(level, email, current_user, url, project)
    |> Ask.Mailer.deliver

    changeset = Invite.changeset(%Invite{}, %{"code" => code, "level" => level, "email" => email, "project_id" => project.id, "inviter_email" => current_user.email})

    Multi.new
    |> Multi.insert(:insert_invite, changeset)
    |> Multi.insert(:insert_log, ActivityLog.create_invite(project, conn, email, level))
    |> Repo.transaction
  end
end
