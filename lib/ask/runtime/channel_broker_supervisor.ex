defmodule Ask.Runtime.ChannelBrokerSupervisor do
  alias Ask.Runtime.ChannelBroker
  use DynamicSupervisor

  def start_link() do
    start_link([])
  end

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_child(nil, _settings), do: start_child(0, %{})

  def start_child(channel_id, settings) do
    DynamicSupervisor.start_child(__MODULE__, child_spec(channel_id, settings))
  end

  def terminate_child(nil), do: terminate_child(0)

  def terminate_child(channel_id) do
    pid = lookup_child(channel_id)
    if pid do
      DynamicSupervisor.terminate_child(__MODULE__, pid)
    else
      :ok
    end
  end

  defp lookup_child(channel_id) do
    case Registry.lookup(:channel_broker_registry, channel_id) do
      [{pid, nil}] ->
        pid
      _ ->
        nil
    end
  end

  defp child_spec(channel_id, settings) do
    %{
      id: "channel_broker_#{channel_id}",
      start: {ChannelBroker, :start_link, [channel_id, settings]}
    }
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
