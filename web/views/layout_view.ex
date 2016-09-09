defmodule Ask.LayoutView do
  use Ask.Web, :view

  def config(conn) do
    nuntium_config = Application.get_env(:ask, Nuntium)

    client_config = %{
      user: current_user(conn).email,

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
