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

  def channel_broker_config do
    %{
      # How many minutes will the ChannelBroker process be idle. Default: 30 minutes.
      # When the process shuts down because of timeout its state is saved to the DB.
      # Low values: the proccess we'll be idle for less time. Less processes will be running
      # concurrently. A too low value could lead to unexpected errors produced by too many
      # unnecessary starts and shutdowns.
      # High values: the process we'll be idle for more time. More processes will be running
      # concurrently. A too high value could lead to a potential (but not expected) risk of
      # overloading the server load.
      shut_down_minutes: env_to_int("SHUT_DOWN_MINUTES", 30),

      # How many minutes the ChannelBroker garbage collector will wait between rounds. Default: 10
      # minutes.
      # Two situations brings the need of running the GC frequently:
      # 1. When the callback are lost, Surveda receives no callbacks after a contact is done.
      # 2. When the callback arrives but the respondent is already deleted or failed.
      # Low values: the GC will run more frequently. A too low value could lead to unnecessary
      # runs of the GC and its corresponding server overload.
      # High values: the GC will run less frequently. A too high value could lead to unnecessary
      # stops of the survey by reaching the channel capacity because of failed contacts or
      # callback losses.
      gc_interval_minutes: env_to_int("CHNL_BKR_GC_INTERVAL_MINUTES", 1),

      # How many hours after the last contact the ChannelBroker waits until a contact is discarded
      # because it's considered outdated. Default: 24 h.
      # Low values: the GC will discard younger contacts. A too low value could lead to discard
      # contacts that aren't really finished. In that scenario, the actual channel capacity
      # wouldn't be honored and the channel could be overloaded.
      # High values: the GC will discard older contacts. A too high value could lead to keep
      # contacts that actually finished, wasting the channel capacity and slowing-down the
      # contact rate.
      # gc_outdate_hours: env_to_int("CHNL_BKR_GC_OUTDATE_HOURS", 24),

      # How long after a call/message has been left idle (no callbacks received)
      # before the GC starts polling the remote channel for its actual state.
      gc_active_idle_minutes: env_to_int("CHNL_BKR_GC_IDLE_MINUTES", 1)
    }
  end

  defp env_to_int(name, default) do
    env = System.get_env(name)

    if env == nil do
      default
    else
      String.to_integer(env)
    end
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
