defmodule Ask.Runtime.ChannelBrokerAgent do
  alias Ask.Runtime.ChannelBrokerRecovery
  use Agent
  use Ask.Model

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

  def save_channel_state(channel_id, state, persist) do
    Agent.update(__MODULE__, fn s -> Map.put(s, channel_id, state) end)

    if persist do
      persist_to_db(channel_id)
    end
  end

  def persist_to_db(channel_id) do
    state = get_channel_state(channel_id)
    ChannelBrokerRecovery.save(state)
  end

  def recover_from_db(channel_id) do
    ChannelBrokerRecovery.fetch(channel_id)
  end

  def is_in_db(channel_id) do
    ChannelBrokerRecovery.saved?(channel_id)
  end
end
