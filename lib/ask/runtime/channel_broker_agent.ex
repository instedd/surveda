defmodule Ask.Runtime.ChannelBrokerAgent do
  alias Ask.Runtime.ChannelBrokerState, as: State
  use Agent

  def start_link do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def get do
    Agent.get(__MODULE__, & &1)
  end

  def update do
    Agent.update(__MODULE__, & &1)
  end

  def recover_state(channel_id) do
    Agent.get(__MODULE__, & &1)
    |> Map.get(channel_id)
  end

  def save_state(%State{channel_id: channel_id} = state) do
    Agent.update(__MODULE__, fn agent ->
      agent
      |> Map.put(channel_id, state)
    end)

    state
  end

  def delete_state(channel_id) do
    Agent.update(__MODULE__, fn agent ->
      Map.delete(agent, channel_id)
    end)
  end
end
