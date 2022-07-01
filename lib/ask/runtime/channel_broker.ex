defmodule Ask.Runtime.ChannelBroker do
  use GenServer

  # Client

  def start_link(channel_id) do
    name = via_tuple(channel_id)
    GenServer.start_link(__MODULE__, channel_id, name: name)
  end

  # Inspired by: https://medium.com/elixirlabs/registry-in-elixir-1-4-0-d6750fb5aeb
  defp via_tuple(channel_id) do
    {:via, Registry, {:channel_broker_registry, channel_id}}
  end

  def foo_call(channel_id) do
    GenServer.call(via_tuple(channel_id), :foo_call)
  end

  # Server (callbacks)

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call(:foo_call, _from, state) do
    {:reply, :ok, state}
  end

end
