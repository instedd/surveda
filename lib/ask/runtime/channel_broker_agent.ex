defmodule Ask.Runtime.ChannelBrokerAgent do
  alias Ask.Runtime.ChannelBrokerRecovery
  use Agent
  use Ask.Model

  def start_link do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def save_channel_state(state) do
    IO.inspect(state, label: "**************************** save_channel_state **************************")
    ChannelBrokerRecovery.save(state)
  end

  def recover_from_db(channel_id) do
    ChannelBrokerRecovery.fetch(channel_id)
  end

  def is_in_db(channel_id) do
    ChannelBrokerRecovery.saved?(channel_id)
  end
end
