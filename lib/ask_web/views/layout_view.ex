defmodule AskWeb.LayoutView do
  use AskWeb, :view
  alias Ask.Config
  alias Ask.{User, Repo}

  def config(conn) do
    version = Application.get_env(:ask, :version)
    sentry_dsn = Sentry.Config.dsn()

    user_email =
      case current_user(conn) do
        nil -> nil
        user -> user.email
      end

    user_settings =
      case current_user(conn) do
        nil ->
          nil

        user ->
          db_user = User |> Repo.get(user.id)

          if db_user do
            db_user.settings
          else
            nil
          end
      end

    client_config = %{
      version: version,
      csrf_token: get_csrf_token(),
      user: user_email,
      user_settings: user_settings,
      sentryDsn: sentry_dsn,
      available_languages_for_numbers: Ask.NumberTranslator.langs(),
      nuntium: Config.provider_config(Nuntium) |> guisso_configs,
      verboice: Config.provider_config(Verboice) |> guisso_configs,
      intercom_app_id: Ask.Intercom.intercom_app_id(),
      default_channel_capacity: Config.default_channel_capacity()
    }

    {:ok, config_json} = client_config |> Poison.encode()
    config_json
  end

  defp guisso_configs(app_env) do
    Enum.map(app_env, &guisso_config/1)
  end

  defp guisso_config(app_env) do
    %{
      baseUrl: app_env[:base_url],
      friendlyName: app_env[:friendly_name],
      channel_ui: app_env[:channel_ui],
      guisso: %{
        baseUrl: app_env[:guisso][:base_url],
        clientId: app_env[:guisso][:client_id],
        appId: app_env[:guisso][:app_id]
      }
    }
  end
end
