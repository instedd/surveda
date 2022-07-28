defmodule Ask.Runtime.ChannelBrokerAgent do
  use Agent

  def start_link do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def get do
    Agent.get(__MODULE__, & &1)
  end

  def get_channel_state(channel_id) do
    Map.get(Agent.get(__MODULE__, & &1), channel_id)
  end

  def update do
    Agent.update(__MODULE__, & &1)
  end

  def save_channel_state(channel_id, state) do
    Agent.update(__MODULE__, fn s -> Map.put(s, channel_id, state) end)
  end
end
