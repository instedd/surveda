Code.ensure_loaded Phoenix.Swoosh

defmodule Ask.Email do
  use Phoenix.Swoosh, view: Ask.EmailView
  alias Swoosh.Email

  def invite(level, email, invited_by, invite_url, project) do
    invited_by_name = name_or_email(invited_by)
    project_name = project_name(project.name)

    subject = "#{invited_by_name} has invited you to collaborate on #{project_name}."

    %Email{}
    |> to({"", email})
    |> from({"InSTEDD Ask", "noreply@instedd.org"})
    |> subject(subject)
    |> render_body(:invite, %{
        url: invite_url,
        invited_by: invited_by_name,
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
