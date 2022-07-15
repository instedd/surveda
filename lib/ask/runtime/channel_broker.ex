defmodule Ask.Runtime.ChannelBroker do
  alias Ask.Runtime.{Channel, ChannelBrokerSupervisor}
  alias Ask.Config
  alias Ask.Repo
  use GenServer

  @timeout_minutes 5
  @timeout @timeout_minutes * 60_000

  # Channels without channel_id (for testing or simulation) share a single process (channel_id: 0)

  def start_link(nil), do: start_link([0, %{}])

  def start_link(channel_id, channel) do
    name = via_tuple(channel_id)
    GenServer.start_link(__MODULE__, [channel_id, channel], name: name)
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

  def check_status(nil, respondent, respondent_state, provider) do
    check_status(0, respondent, respondent_state, provider)
  end

  def callback_recieved(channel_id, respondent, respondent_state, provider) do
    call_gen_server(channel_id, {:callback_recieved, respondent, respondent_state, provider})
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
        {:ok, pid} = ChannelBrokerSupervisor.start_child(channel_id, get_channel(channel_id))
        pid
    end
  end

  defp get_channel(0), do: %{settings: %{}}

  defp get_channel(channel_id) do
    channel = Repo.get(Ask.Channel, channel_id)
    if (channel) do
      channel
    else
      %{settings: %{}}
    end
  end

  # Server (callbacks)

  @impl true
  def init([channel_id, %{settings: settings} = channel]) do
    {
      :ok,
      %{
        channel_id: channel_id,
        channel: channel,
        # capacity: maximum concurrect SMS or IVR calls supported by the channel
        capacity: Map.get(settings, :capacity, Config.default_channel_capacity()),
        # contacts_queue: SMS messages or IVR calls waiting to be sent because of the channel capacity
        contacts_queue: :pqueue.new(),
        # active_contacts: amount of active (or queued outside Surveda) SMS messages or IVR calls
        active_contacts: 0,
      },
      @timeout
    }
  end

  def queue_contact(
        %{
          contacts_queue: contacts_queue
        } = state,
        contact_args
      ) do
    new_contacts_queue =
      :pqueue.in(contact_args, contacts_queue)

    %{ state | contacts_queue: new_contacts_queue }
  end

  def can_unqueue(
        %{
          capacity: capacity,
          active_contacts: active_contacts,
          contacts_queue: contacts_queue
        } = _state
      ) do
    cond do
      :pqueue.is_empty(contacts_queue) -> false
      active_contacts >= capacity -> false
      true -> true
    end
  end

  def unqueue_and_contact(
        %{
          active_contacts: active_contacts,
          contacts_queue: contacts_queue
        } = state,
        contact
      ) do

    {{_unqueue_res, unqueued_contact}, contacts_queue} = :pqueue.out(contacts_queue)

    count = contact.(unqueued_contact)

    state = %{
      state |
        active_contacts: active_contacts + count,
        contacts_queue: contacts_queue
    }

    state
  end

  # def deactivate_respondent(
  #       %{
  #         active_respondents: active_respondents,
  #         respondents_queue: respondents_queue
  #       } = state,
  #       respondent_id,
  #       re_enqueue
  #     ) do
  #   if re_enqueue do
  #     {respondent, token, not_before, not_after} = Map.get(active_respondents, respondent_id)

  #     new_respondents_queue =
  #       :pqueue.in(respondents_queue, {respondent, token, not_before, not_after})

  #     Map.put(state, :respondents_queue, new_respondents_queue)
  #   end

  #   new_active_respondents = Map.delete(active_respondents, respondent_id)
  #   state = Map.put(state, :active_respondents, new_active_respondents)
  #   state
  # end

  @impl true
  def handle_call(
        {:ask, channel, respondent, token, reply},
        _from,
        state
      ) do

    contact_args = {respondent, token, reply}
    state = queue_contact(state, contact_args)

    state =
      if can_unqueue(state) do
        contact = fn ({queued_respondent, token, reply}) ->
          Channel.ask(channel, queued_respondent, token, reply)
        end

        unqueue_and_contact(state, contact)
      else
        state
      end
    {:reply, respondent, state, @timeout}
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

    setup_response = Channel.setup(channel, respondent, token, not_before, not_after)

    {:reply, setup_response, state, @timeout}

    # contact_args = {respondent_id, token, not_before, not_after}

    # {setup_response, new_state} = handle_setup("nuntium", channel, state, contact_args)

    # {:reply, setup_response, new_state, @timeout}
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
  def handle_call({:callback_recieved, _respondent, _respondent_state, _provider}, _from, %{channel_id: _channel_id} = state) do

    {:reply, :ok, state, @timeout}
  end

  @impl true
  def handle_info(:timeout, channel_id) do
    ChannelBrokerSupervisor.terminate_child(channel_id)
  end

  # defp handle_setup("nuntium" = _provider, _channel, state, _contact_args) do
  #   {:ok, state}
  # end

  # defp handle_setup("verboice" = _provider, channel, state, contact_args) do
  #   queue_contact(state, contact_args)
  #   %{
  #     contact_response: setup_response,
  #     new_state: new_state
  #   } = if can_unqueue(state) do
  #     contact = fn ({respondent_id, token, not_before, not_after}) ->
  #       respondent = Repo.get(Respondent, respondent_id)
  #       Channel.setup(channel, respondent, token, not_before, not_after)
  #     end

  #     unqueue_and_contact(
  #       state,
  #       contact
  #     )
  #   else
  #     %{
  #       contact_response: {:ok, %{verboice_call_id: 9999}},
  #       new_state: state
  #     }
  #   end

  #   {setup_response, new_state}
  # end
end
