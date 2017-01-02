defmodule Ask.InviteView do
  use Ask.Web, :view

  def render("accept_invitation.json", %{project_id: project_id}) do
    %{data:
      %{
        project_id: project_id
      }
    }
  end

  def render("invite.json", %{project_id: project_id, email: email, code: code, level: level}) do
    %{data:
      %{
        project_id: project_id,
        email: email,
        code: code,
        level: level
      }
    }
  end
end
