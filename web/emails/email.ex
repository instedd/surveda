Code.ensure_loaded Phoenix.Swoosh

defmodule Ask.Email do
  use Phoenix.Swoosh, view: Ask.EmailView
  alias Swoosh.Email
  require Logger
  alias Ask.Router.Helpers

  def invite(level, email, invited_by, invite_url, conn, project) do
    invited_by_name = name_or_email(invited_by)
    project_name = project_name(project.name)
    
    subject = "#{invited_by_name} has invited you to collaborate on #{project_name}."

    %Email{}
    |> to({"", email})
    |> from({"InSTEDD Ask", "noreply@instedd.org"})
    |> subject(subject)
    |> text_body("#{subject}. Please follow this link to join: #{invite_url}")
    |> render_body("invite.html", %{
        url: invite_url, 
        invited_by: invited_by_name,
        logo: Helpers.static_path(conn, "/images/email-logo@2x.png"),
        explanation: explanation(level),
        project_name: project_name        
      })
  end

  defp project_name(""), do: "an Ask project"
  defp project_name(nil), do: "an Ask project"
  defp project_name(name), do: "#{name}"

  defp explanation("editor"), do: "You'll be able to manage surveys, questionnaires, content and collaborators."
  defp explanation(_), do: "You'll be able to browse surveys, questionnaires, content and collaborators."  

  defp name_or_email(user) do
    case {user.name, user.email} do
      {nil, email} -> email
      {"", email} -> email
      {name, _} -> name
    end
  end
end
