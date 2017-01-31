Code.ensure_loaded Phoenix.Swoosh

defmodule Ask.Email do
  use Phoenix.Swoosh, view: Ask.EmailView
  alias Swoosh.Email
  require Logger

  def invite(email, invited_by, invite_url) do
    invited_by_name = name_or_email(invited_by)
    %Email{}
    |> to(user_email(invited_by))
    |> from({"InSTEDD Ask", "noreply@instedd.org"})
    |> subject("#{invited_by_name} has invited you to collaborate on an Ask project")
    |> text_body("#{invited_by_name} has invited you to collaborate on an Ask project. Please follow this link to join: #{invite_url}")
    |> render_body("invite.html", %{url: invite_url, invited_by: invited_by_name})
  end

  defp user_email(user) do
    {user.name, user.email}
  end

  defp name_or_email(user) do
    case {user.name, user.email} do
      {nil, email} -> email
      {"", email} -> email
      {name, _} -> name
    end
  end
end
