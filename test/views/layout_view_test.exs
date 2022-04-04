defmodule Ask.LayoutViewTest do
  use Ask.ConnCase, async: true

  setup do
    Ask.Config.start_link()
    :ok
  end

  defp test_rendered_guisso_config(env, json_root) do
    rendered_config =
      assign(build_conn(), :current_user, %{name: "John Doe", email: "john@doe.com", id: 3})
      |> Ask.LayoutView.config()
      |> Poison.Parser.parse!()

    assert rendered_config[json_root] != nil

    root = rendered_config[json_root] |> hd

    assert root["baseUrl"] == env[:base_url]
    assert root["guisso"]["baseUrl"] == env[:guisso][:base_url]
    assert root["guisso"]["clientId"] == env[:guisso][:client_id]
    assert root["guisso"]["appId"] == env[:guisso][:app_id]
  end

  test "renders Nuntium Guisso config" do
    config = Application.get_env(:ask, Nuntium)
    test_rendered_guisso_config(config, "nuntium")
  end

  test "renders Verboice Guisso config" do
    config = Application.get_env(:ask, Verboice)
    test_rendered_guisso_config(config, "verboice")
  end
end
