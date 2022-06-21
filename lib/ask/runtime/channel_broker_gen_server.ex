defmodule Ask.Runtime.ChannelBrokerGenServer do
  use GenServer

  # Callbacks

  @impl true
  def init(state) do
    IO.inspect(state, label: "-----------------Channel Broker init")
    {:ok, state}
  end
end
