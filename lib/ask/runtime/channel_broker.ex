defmodule Ask.Runtime.ChannelBroker do
  alias Ask.Runtime.Channel
  alias Ask.Config
  use GenServer

  # Channels without channel_id (for testing or simulation) share a single process (channel_id: 0)

  def start_link(nil), do: start_link([0, %{}])

  def start_link(channel_id, settings) do
    name = via_tuple(channel_id)
    GenServer.start_link(__MODULE__, [channel_id, settings], name: name)
  end

  # Inspired by: https://medium.com/elixirlabs/registry-in-elixir-1-4-0-d6750fb5aeb
  defp via_tuple(channel_id) do
    {:via, Registry, {:channel_broker_registry, channel_id}}
  end

  def prepare(nil, channel), do: prepare(0, channel)

  def prepare(channel_id, channel) do
    GenServer.call(via_tuple(channel_id), {:prepare, channel})
  end

  def setup(nil, channel, respondent, token, not_before, not_after) do
    setup(0, channel, respondent, token, not_before, not_after)
  end

  def setup(channel_id, channel, respondent, token, not_before, not_after) do
    GenServer.call(via_tuple(channel_id), {:setup, channel, respondent, token, not_before, not_after})
  end

  def has_delivery_confirmation?(nil, channel), do: has_delivery_confirmation?(0, channel)

  def has_delivery_confirmation?(channel_id, channel) do
    GenServer.call(via_tuple(channel_id), {:has_delivery_confirmation?, channel})
  end

  def ask(nil, channel, respondent, token, reply), do: ask(0, channel, respondent, token, reply)

  def ask(channel_id, channel, respondent, token, reply) do
    GenServer.call(via_tuple(channel_id), {:ask, channel, respondent, token, reply})
  end

  def has_queued_message?(nil, channel, channel_state) do
    has_queued_message?(0, channel, channel_state)
  end

  def has_queued_message?(channel_id, channel, channel_state) do
    GenServer.call(via_tuple(channel_id), {:has_queued_message?, channel, channel_state})
  end

  def cancel_message(nil, channel, channel_state) do
    cancel_message(0, channel, channel_state)
  end

  def cancel_message(channel_id, channel, channel_state) do
    GenServer.call(via_tuple(channel_id), {:cancel_message, channel, channel_state})
  end

  def message_expired?(nil, channel, channel_state) do
    message_expired?(0, channel, channel_state)
  end

  def message_expired?(channel_id, channel, channel_state) do
    GenServer.call(via_tuple(channel_id), {:message_expired?, channel, channel_state})
  end

  def check_status(nil, channel) do
    check_status(0, channel)
  end

  def check_status(channel_id, channel) do
    GenServer.call(via_tuple(channel_id), {:check_status, channel})
  end

  # Server (callbacks)

  @impl true
  def init([channel_id, settings]) do
    {
      :ok,
      %{
        channel_id: channel_id,
        capacity: Map.get(settings, :capacity, Config.default_channel_capacity()),
        active_respondents: []
      }
    }
  end

  @impl true
  def handle_call({
    :ask, channel,
    %{id: respondent_id} = respondent, token, reply},
    _from,
    %{active_respondents: active_respondents
  } = state) do
    reply = if (respondent_id in active_respondents) do
      Channel.ask(channel, respondent, token, reply)
    else
      {:error, :inactive_respondent}
    end
    {:reply, reply, state}
  end

  @impl true
  def handle_call(
    {
      :setup, channel, %{id: respondent_id} = respondent, token, not_before, not_after
    }, _from,
    %{
      capacity: capacity,
      active_respondents: active_respondents
    } = state) do
      {reply, state} = if (length(active_respondents) > capacity) do
        {
          {:error, :channel_overloaded},
          state
        }
      else
        {
          Channel.setup(channel, respondent, token, not_before, not_after),
          Map.put(state, :active_respondents, active_respondents ++ [respondent_id])
        }
      end
      {:reply, reply, state}
  end

  @impl true
  def handle_call({:prepare, channel}, _from, state) do
    reply = Channel.prepare(channel)
    {:reply, reply, state}
  end

  @impl true
  def handle_call({:has_delivery_confirmation?, channel}, _from, state) do
    reply = Channel.has_delivery_confirmation?(channel)
    {:reply, reply, state}
  end

  @impl true
  def handle_call({:has_queued_message?, channel, channel_state}, _from, state) do
    reply = Channel.has_queued_message?(channel, channel_state)
    {:reply, reply, state}
  end

  @impl true
  def handle_call({:cancel_message, channel, channel_state}, _from, state) do
    reply = Channel.cancel_message(channel, channel_state)
    {:reply, reply, state}
  end

  @impl true
  def handle_call({:message_expired?, channel, channel_state}, _from, state) do
    reply = Channel.message_expired?(channel, channel_state)
    {:reply, reply, state}
  end

  @impl true
  def handle_call({:check_status, channel}, _from, state) do
    reply = Channel.check_status(channel)
    {:reply, reply, state}
  end
end
