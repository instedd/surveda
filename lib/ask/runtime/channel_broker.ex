defmodule Ask.Runtime.ChannelBroker do
  alias Ask.Runtime.Channel
  use GenServer

  def prepare(channel) do
    Channel.prepare(channel)
  end

  def setup(channel, respondent, token, not_before, not_after) do
    Channel.setup(channel, respondent, token, not_before, not_after)
  end

  def has_delivery_confirmation?(channel) do
    Channel.has_delivery_confirmation?(channel)
  end

  def ask(channel, respondent, token, reply) do
    Channel.ask(channel, respondent, token, reply)
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
