Code.ensure_loaded Phoenix.Swoosh

defmodule Ask.Email do
  use Phoenix.Swoosh, view: Ask.EmailView
  alias Swoosh.Email
  alias Ask.ConfigHelper

  def invite(level, email, invited_by, invite_url, project) do
    invited_by_name = name_or_email(invited_by)
    project_name = project_name(project.name)

    subject = "#{invited_by_name} has invited you to collaborate on #{project_name}."

    %Email{}
    |> to({"", email})
    |> from(smtp_from_address())
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
    |> from(smtp_from_address())
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
    |> from(smtp_from_address())
    |> subject("Channel is down")
    |> render_body(:channel_down, %{
      channel_name: channel.name,
      errors: messages,
      url: url
    })
  end

  def channel_error(email, channel, code) do
    url = Ask.Endpoint.url <> "/channels/#{channel.id}/settings"
    %Email{}
    |> to({"", email})
    |> from(smtp_from_address())
    |> subject("Error when connecting with channel")
    |> render_body(:channel_error, %{
      channel_name: channel.name,
      code: code,
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

  def smtp_from_address do
    {_, smtp_from_address} =
      smtp_from_address(ConfigHelper.get_config(__MODULE__, :smtp_from_address))

    smtp_from_address
  end

  def smtp_from_address(value_from_config) do
    regex = ~r/ <.+@.+>/

    case String.match?(value_from_config, regex) do
      true ->
        [{start_ix, end_ix}] = regex |> Regex.run(value_from_config, return: :index)

        {:ok,
         {String.slice(value_from_config, 0, start_ix),
          String.slice(value_from_config, start_ix + 2, end_ix - 3)}}

      _ ->
        Ask.Logger.error(
          "Invalid SMTP Address \"#{value_from_config}\". Valid example: \"Example name <example@email>\""
        )

        {:error, {"InSTEDD Surveda", "noreply@instedd.org"}}
    end
  end
end
