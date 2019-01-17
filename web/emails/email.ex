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
    |> from({"InSTEDD Surveda", "noreply@instedd.org"})
    |> subject(subject)
    |> render_body(:invite, %{
        url: invite_url,
        invited_by: invited_by_name,
        explanation: explanation(level),
        project_name: project_name
      })
  end

  def notify(level, email, invited_by, invite_url, project) do
    invited_by_name = name_or_email(invited_by)
    project_name = project_name(project.name)

    subject = "#{invited_by_name} has added you as a collaborator on #{project_name}."

    %Email{}
    |> to({"", email})
    |> from({"InSTEDD Surveda", "noreply@instedd.org"})
    |> subject(subject)
    |> render_body(:notify, %{
        url: invite_url,
        invited_by: invited_by_name,
        explanation: explanation_notify(level),
        project_name: project_name
      })
  end

  def channel_down(email, channel, messages) do
    url = Ask.Endpoint.url <> "/channels/#{channel.id}/settings"
    %Email{}
    |> to({"", email})
    |> from({"InSTEDD Surveda", "noreply@instedd.org"})
    |> subject("Channel is down")
    |> render_body(:channel_down, %{
      channel_name: channel.name,
      errors: messages,
      url: url
    })
  end

  defp project_name(""), do: "a Surveda project"
  defp project_name(nil), do: "a Surveda project"
  defp project_name(name), do: "#{name}"

  defp explanation("editor"), do: "You'll be able to manage surveys, questionnaires, content and collaborators."
  defp explanation(_), do: "You'll be able to browse surveys, questionnaires, content and collaborators."

  defp explanation_notify("editor"), do: "You are able to manage surveys, questionnaires, content and collaborators."
  defp explanation_notify(_), do: "You are able to browse surveys, questionnaires, content and collaborators."

  defp name_or_email(user) do
    case {user.name, user.email} do
      {nil, email} -> email
      {"", email} -> email
      {name, _} -> name
    end
  end
end
