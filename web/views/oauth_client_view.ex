defmodule Ask.OAuthClientView do
  use Ask.Web, :view

  def render("index.json", %{authorizations: auths}) do
    %{data: auths |> Enum.map(fn auth -> auth.provider end)}
  end

end
