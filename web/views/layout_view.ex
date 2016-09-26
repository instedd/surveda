defmodule Ask.LayoutView do
  use Ask.Web, :view

  def config(conn) do
    version = Application.get_env(:ask, :version)

    client_config = %{
      version: version,
      user: current_user(conn).email,
      nuntium: Application.get_env(:ask, Nuntium) |> guisso_config,
      verboice: Application.get_env(:ask, Verboice) |> guisso_config
    }

    {:ok, config_json} = client_config |> Poison.encode
    config_json
  end

  defp guisso_config(app_env) do
    %{
      baseUrl: app_env[:base_url],
      guisso: %{
        baseUrl: app_env[:guisso][:base_url],
        clientId: app_env[:guisso][:client_id],
        appId: app_env[:guisso][:app_id]
      }
    }
  end
end
