defmodule Ask.Runtime.ChannelBroker do
  alias Ask.Runtime.Channel
  use GenServer

  # Handle all the channels without channel_id (for testing or simulation) in a single process.
  def prepare(nil, channel), do: prepare(0, channel)

  def prepare(channel_id, channel) do
    GenServer.call(via_tuple(channel_id), {:prepare, channel})
  end

  # Handle all the channels without channel_id (for testing or simulation) in a single process.
  def setup(nil, channel, respondent, token, not_before, not_after) do
    setup(0, channel, respondent, token, not_before, not_after)
  end

  def setup(channel_id, channel, respondent, token, not_before, not_after) do
    GenServer.call(via_tuple(channel_id), {:setup, channel, respondent, token, not_before, not_after})
  end

  def has_delivery_confirmation?(channel) do
    Channel.has_delivery_confirmation?(channel)
  end

  # Handle all the channels without channel_id (for testing or simulation) in a single process.
  def ask(nil, channel, respondent, token, reply), do: ask(0, channel, respondent, token, reply)

  def ask(channel_id, channel, respondent, token, reply) do
    GenServer.call(via_tuple(channel_id), {:ask, channel, respondent, token, reply})
  end

  def has_queued_message?(channel, channel_state) do
    Channel.has_queued_message?(channel, channel_state)
  end

  def cancel_message(channel, channel_state) do
    Channel.cancel_message(channel, channel_state)
  end

  def message_expired?(channel, channel_state) do
    Channel.message_expired?(channel, channel_state)
  end

  def check_status(channel) do
    Channel.check_status(channel)
  end

  # Client

  def start_link(nil), do: start_link(0)

  def start_link(channel_id) do
    name = via_tuple(channel_id)
    GenServer.start_link(__MODULE__, channel_id, name: name)
  end

  # Inspired by: https://medium.com/elixirlabs/registry-in-elixir-1-4-0-d6750fb5aeb
  defp via_tuple(channel_id) do
    {:via, Registry, {:channel_broker_registry, channel_id}}
  end

  # Server (callbacks)

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:ask, channel, respondent, token, reply}, _from, state) do
    reply = Channel.ask(channel, respondent, token, reply)
    {:reply, reply, state}
  end

  @impl true
  def handle_call({:setup, channel, respondent, token, not_before, not_after}, _from, state) do
    reply = Channel.setup(channel, respondent, token, not_before, not_after)
    {:reply, reply, state}
  end

  @impl true
  def handle_call({:prepare, channel}, _from, state) do
    reply = Channel.prepare(channel)
    {:reply, reply, state}
  end
end
