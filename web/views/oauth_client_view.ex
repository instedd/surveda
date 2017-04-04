defmodule Ask.OAuthClientView do
  use Ask.Web, :view

  def render("index.json", %{authorizations: auths}) do
    %{data: auths |> Enum.map(fn auth ->
      %{
        provider: auth.provider,
        baseUrl: auth.base_url,
      }
    end)}
  end
end
