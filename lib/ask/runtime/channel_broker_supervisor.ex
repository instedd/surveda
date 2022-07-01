defmodule Ask.Runtime.ChannelBrokerSupervisor do
  alias Ask.Runtime.ChannelBroker
  use DynamicSupervisor

  def start_link() do
    start_link([])
  end

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_child(channel_id) do
    DynamicSupervisor.start_child(__MODULE__, child_spec(channel_id))
  end

  defp child_spec(channel_id) do
    %{
      id: "channel_broker_#{channel_id}",
      start: {ChannelBroker, :start_link, [channel_id]}
    }
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
