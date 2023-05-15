defmodule Ask.Runtime.ChannelBrokerSupervisor do
  alias Ask.Runtime.{ChannelBroker, ChannelBrokerAgent}
  use DynamicSupervisor

  def start_link() do
    start_link([])
  end

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_child(channel_id, channel_type, settings) do
    state = ChannelBrokerAgent.recover_state(channel_id)
    spec = child_spec(channel_id, channel_type, settings, state)
    DynamicSupervisor.start_child(__MODULE__, spec)
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

  def terminate_children() do
    DynamicSupervisor.which_children(__MODULE__)
    |> Enum.each(fn {_, pid, _, _} ->
      terminate_child(pid)
    end)
  end

  defp lookup_child(channel_id) do
    case Registry.lookup(:channel_broker_registry, channel_id) do
      [{pid, nil}] ->
        pid

      _ ->
        nil
    end
  end

  defp child_spec(channel_id, channel_type, settings, nil) do
    %{
      id: "channel_broker_#{channel_id}",
      start: {ChannelBroker, :start_link, [channel_id, channel_type, settings]}
    }
  end

  defp child_spec(channel_id, channel_type, settings, state) do
    %{
      id: "channel_broker_#{channel_id}",
      start: {ChannelBroker, :start_link, [channel_id, channel_type, settings, state]}
    }
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
