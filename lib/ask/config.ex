defmodule Ask.Config do
  use GenServer

  @server_ref {:global, __MODULE__}

  def server_ref, do: @server_ref

  def start_link do
    GenServer.start_link(__MODULE__, [], name: @server_ref)
  end

  def init([]) do
    {:ok,
     %{
       Nuntium => read_config(Nuntium, "NUNTIUM"),
       Verboice => read_config(Verboice, "VERBOICE")
     }}
  end

  def provider_config(provider) do
    GenServer.call(@server_ref, {:provider_config, provider})
  end

  def provider_config(provider, base_url) do
    GenServer.call(@server_ref, {:provider_config, provider, base_url})
  end

  def handle_call({:provider_config, provider}, _from, state) do
    configs = state[provider]
    {:reply, configs, state}
  end

  def handle_call({:provider_config, provider, base_url}, _from, state) do
    result =
      state[provider]
      |> Enum.find(fn config ->
        config[:base_url] == base_url
      end)

    {:reply, result, state}
  end

  def default_channel_capacity do
    System.get_env("DEFAULT_CHANNEL_CAPACITY") || 100
  end

  defp read_config(module_name, env_var_name) do
    config =
      read_config_env_var(env_var_name) ||
        read_config_traditional(module_name)

    cond do
      Keyword.keyword?(config) -> [config]
      config == nil -> []
      true -> config
    end
  end

  defp read_config_traditional(module_name) do
    Application.get_env(:ask, module_name)
  end

  defp read_config_env_var(env_var_name) do
    read_config_env_var_instances(env_var_name) ||
      read_config_env_var_single(env_var_name)
  end

  defp read_config_env_var_instances(env_var_name) do
    instances = System.get_env("#{env_var_name}_INSTANCES")

    if instances do
      instances = instances |> String.to_integer()

      1..instances
      |> Enum.map(fn index ->
        read_config_env_var_instance(env_var_name, index)
      end)
    else
      nil
    end
  end

  defp read_config_env_var_instance(env_var_name, index) do
    [
      base_url: read_env!(env_var_name, index, "BASE_URL"),
      friendly_name: read_env!(env_var_name, index, "FRIENDLY_NAME"),
      guisso: [
        base_url: read_env!(env_var_name, index, "GUISSO_BASE_URL"),
        client_id: read_env!(env_var_name, index, "CLIENT_ID"),
        client_secret: read_env!(env_var_name, index, "CLIENT_SECRET"),
        app_id: read_env!(env_var_name, index, "APP_ID")
      ],
      channel_ui: read_env!(env_var_name, index, "CHANNEL_UI") == "true"
    ]
  end

  defp read_config_env_var_single(env_var_name) do
    base_url = read_env(env_var_name, "BASE_URL")

    if base_url do
      [
        base_url: base_url,
        guisso: [
          base_url: read_env!(env_var_name, "GUISSO_BASE_URL"),
          client_id: read_env!(env_var_name, "CLIENT_ID"),
          client_secret: read_env!(env_var_name, "CLIENT_SECRET"),
          app_id: read_env!(env_var_name, "APP_ID")
        ],
        channel_ui: read_env!(env_var_name, "CHANNEL_UI") == "true"
      ]
    else
      nil
    end
  end

  defp read_env(env_var_name, name) do
    System.get_env("#{env_var_name}_#{name}")
  end

  defp read_env!(env_var_name, index, name) do
    key = "#{env_var_name}_#{name}_#{index}"
    System.get_env(key) || raise("Missing ENV key: #{key}")
  end

  defp read_env!(env_var_name, name) do
    key = "#{env_var_name}_#{name}"
    System.get_env(key) || raise("Missing ENV key: #{key}")
  end
end
