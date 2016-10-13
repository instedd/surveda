defmodule Ask.LayoutView do
  use Ask.Web, :view

  def config(conn) do
    version = Application.get_env(:ask, :version)
    nuntium_config = Application.get_env(:ask, Nuntium)
    sentry_dsn = Application.get_env(:sentry, :public_dsn)

    client_config = %{
      version: version,
      user: current_user(conn).email,
      sentryDsn: sentry_dsn,

      nuntium: %{
        baseUrl: nuntium_config[:base_url],
        guisso: %{
          baseUrl: nuntium_config[:guisso][:base_url],
          clientId: nuntium_config[:guisso][:client_id],
          appId: nuntium_config[:guisso][:app_id]
        }
      }
    }

    {:ok, config_json} = client_config |> Poison.encode
    config_json
  end
end
