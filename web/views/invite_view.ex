defmodule Ask.InviteView do
  use Ask.Web, :view

  def render("accept_invitation.json", %{level: level, project_id: project_id}) do
    %{data:
      %{
        project_id: project_id,
        level: level
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

  def render("error.json", %{error: error}) do
    %{data:
      %{
        error: error
      }
    }
  end
end
