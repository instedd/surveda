defmodule Ask.Runtime.ChannelBroker do
  alias Ask.Runtime.{Channel, ChannelBrokerSupervisor}
  alias Ask.Config
  import Ecto.Query
  alias Ask.Repo
  use GenServer

  @timeout_minutes 5
  @timeout @timeout_minutes * 60_000

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
    call_gen_server(channel_id, {:prepare, channel})
  end

  def setup(nil, channel, respondent, token, not_before, not_after) do
    setup(0, channel, respondent, token, not_before, not_after)
  end

  def setup(channel_id, channel, respondent, token, not_before, not_after) do
    call_gen_server(channel_id, {:setup, channel, respondent, token, not_before, not_after})
  end

  def has_delivery_confirmation?(nil, channel), do: has_delivery_confirmation?(0, channel)

  def has_delivery_confirmation?(channel_id, channel) do
    call_gen_server(channel_id, {:has_delivery_confirmation?, channel})
  end

  def ask(nil, channel, respondent, token, reply), do: ask(0, channel, respondent, token, reply)

  def ask(channel_id, channel, respondent, token, reply) do
    call_gen_server(channel_id, {:ask, channel, respondent, token, reply})
  end

  def has_queued_message?(nil, channel, channel_state) do
    has_queued_message?(0, channel, channel_state)
  end

  def has_queued_message?(channel_id, channel, channel_state) do
    call_gen_server(channel_id, {:has_queued_message?, channel, channel_state})
  end

  def cancel_message(nil, channel, channel_state) do
    cancel_message(0, channel, channel_state)
  end

  def cancel_message(channel_id, channel, channel_state) do
    call_gen_server(channel_id, {:cancel_message, channel, channel_state})
  end

  def message_expired?(nil, channel, channel_state) do
    message_expired?(0, channel, channel_state)
  end

  def message_expired?(channel_id, channel, channel_state) do
    call_gen_server(channel_id, {:message_expired?, channel, channel_state})
  end

  def check_status(nil, channel) do
    check_status(0, channel)
  end

  def check_status(channel_id, channel) do
    call_gen_server(channel_id, {:check_status, channel})
  end

  defp call_gen_server(channel_id, message) do
    pid = find_or_start_process(channel_id)
    GenServer.call(pid, message)
  end

  defp find_or_start_process(channel_id) do
    case Registry.lookup(:channel_broker_registry, channel_id) do
      [{pid, _}] ->
        pid
      [] ->
        {:ok, pid} = ChannelBrokerSupervisor.start_child(channel_id, channel_settings(channel_id))
        pid
    end
  end

  defp channel_settings(0), do: %{}

  defp channel_settings(channel_id) do
    query = from c in "channels", where: c.id == ^channel_id, select: c.settings
    settings = Repo.one(query)
    if (settings) do
      Poison.decode!(settings)
    else
      %{}
    end
  end

  # Server (callbacks)

  @impl true
  def init([channel_id, settings]) do
    {
      :ok,
      %{
        channel_id: channel_id,
        capacity: Map.get(settings, :capacity, Config.default_channel_capacity()),
        active_respondents: Map.new(),
        respondents_queue: :pqueue.new()
      },
      @timeout
    }
  end

  def queue_respondent(
        %{
          respondents_queue: respondents_queue
        } = state,
        respondent,
        token,
        not_before,
        not_after
      ) do
    new_respondents_queue =
      :pqueue.in({respondent, token, not_before, not_after}, respondents_queue)

    state = Map.put(state, :respondents_queue, new_respondents_queue)
    state
  end

  def can_unqueue(
        %{
          capacity: capacity,
          active_respondents: active_respondents,
          respondents_queue: respondents_queue
        } = _state
      ) do
    cond do
      :pqueue.is_empty(respondents_queue) -> false
      length(Map.keys(active_respondents)) >= capacity -> false
      true -> true
    end
  end

  def activate_respondent(
        %{
          active_respondents: active_respondents,
          respondents_queue: respondents_queue
        } = state,
        channel
      ) do
    {{_unqueue_res, unqueued_item}, new_respondents_queue} = :pqueue.out(respondents_queue)
    {respondent, token, not_before, not_after} = unqueued_item

    new_active_respondents =
      Map.put(active_respondents, respondent.id, {respondent, token, not_before, not_after})

    state = Map.put(state, :active_respondents, new_active_respondents)
    state = Map.put(state, :respondents_queue, new_respondents_queue)
    setup_response = Channel.setup(channel, respondent, token, not_before, not_after)
    {state, setup_response}
  end

  def deactivate_respondent(
        %{
          active_respondents: active_respondents,
          respondents_queue: respondents_queue
        } = state,
        respondent_id,
        re_enqueue
      ) do
    if re_enqueue do
      {respondent, token, not_before, not_after} = Map.get(active_respondents, respondent_id)

      new_respondents_queue =
        :pqueue.in(respondents_queue, {respondent, token, not_before, not_after})

      Map.put(state, :respondents_queue, new_respondents_queue)
    end

    new_active_respondents = Map.delete(active_respondents, respondent_id)
    state = Map.put(state, :active_respondents, new_active_respondents)
    state
  end

  @impl true
  def handle_call(
        {:ask, channel, %{id: respondent_id} = respondent, token, reply},
        _from,
        %{active_respondents: active_respondents} = state
      ) do
    reply =
      if respondent_id in Map.keys(active_respondents) do
        Channel.ask(channel, respondent, token, reply)
      else
        # This should be an error or we should check if it's in the queue?
        {:error, :inactive_respondent}
      end

    {:reply, reply, state, @timeout}
  end

  @impl true
  def handle_call(
        {
          :setup,
          channel,
          respondent,
          token,
          not_before,
          not_after
        },
        _from,
        state
      ) do
    state = queue_respondent(state, respondent, token, not_before, not_after)

    {state, setup_response} = if can_unqueue(state) do
      activate_respondent(state, channel)
    else
      {state, {:ok, %{verboice_call_id: 9999}}}
    end

    {:reply, setup_response, state, @timeout}
  end

  @impl true
  def handle_call({:prepare, channel}, _from, state) do
    reply = Channel.prepare(channel)
    {:reply, reply, state, @timeout}
  end

  @impl true
  def handle_call({:has_delivery_confirmation?, channel}, _from, state) do
    reply = Channel.has_delivery_confirmation?(channel)
    {:reply, reply, state, @timeout}
  end

  @impl true
  def handle_call({:has_queued_message?, channel, channel_state}, _from, state) do
    reply = Channel.has_queued_message?(channel, channel_state)
    {:reply, reply, state, @timeout}
  end

  @impl true
  def handle_call({:cancel_message, channel, channel_state}, _from, state) do
    reply = Channel.cancel_message(channel, channel_state)
    {:reply, reply, state, @timeout}
  end

  @impl true
  def handle_call({:message_expired?, channel, channel_state}, _from, state) do
    reply = Channel.message_expired?(channel, channel_state)
    {:reply, reply, state, @timeout}
  end

  @impl true
  def handle_call({:check_status, channel}, _from, state) do
    reply = Channel.check_status(channel)
    {:reply, reply, state, @timeout}
  end

  @impl true
  def handle_info(:timeout, channel_id) do
    ChannelBrokerSupervisor.terminate_child(channel_id)
  end
end
