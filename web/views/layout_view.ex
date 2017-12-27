defmodule Ask.LayoutView do
  use Ask.Web, :view
  alias Ask.Config

  def config(conn) do
    version = Application.get_env(:ask, :version)
    sentry_dsn = Application.get_env(:sentry, :public_dsn)
    user_email = case current_user(conn) do
      nil -> nil
      user -> user.email
    end

    client_config = %{
      version: version,
      csrf_token: get_csrf_token(),
      user: user_email,
      sentryDsn: sentry_dsn,
      available_languages_for_numbers: Ask.NumberTranslator.langs(),
      nuntium: Config.provider_config(Nuntium) |> guisso_configs,
      verboice: Config.provider_config(Verboice) |> guisso_configs
    }

    {:ok, config_json} = client_config |> Poison.encode
    config_json
  end

  defp guisso_configs(app_env) do
    Enum.map(app_env, &guisso_config/1)
  end

  defp guisso_config(app_env) do
    %{
      baseUrl: app_env[:base_url],
      friendlyName: app_env[:friendly_name],
      guisso: %{
        baseUrl: app_env[:guisso][:base_url],
        clientId: app_env[:guisso][:client_id],
        appId: app_env[:guisso][:app_id]
      }
    }
  end
end
