defmodule Ask.Runtime.ChannelBroker do
  alias Ask.Runtime.{Channel, ChannelBrokerSupervisor, NuntiumChannel}
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

  def check_status(nil, respondent, respondent_state, provider) do
    check_status(0, respondent, respondent_state, provider)
  end

  def callback_recieved(channel_id, channel, respondent, respondent_state, provider) do
    call_gen_server(
      channel_id,
      {:callback_recieved, channel, respondent, respondent_state, provider}
    )
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

    if settings do
      Poison.decode!(settings)
    else
      %{}
    end
  end

  defp channel_provider(channel_id) do
    query = from c in "channels", where: c.id == ^channel_id, select: c.provider
    provider = Repo.one(query)

    if provider do
      provider
    else
      ""
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
        active_contacts: 0,
        contacts_queue: :pqueue.new()
      },
      @timeout
    }
  end

  def queue_contact(
        %{
          contacts_queue: contacts_queue
        } = state,
        contact,
        size
      ) do
    new_contacts_queue = :pqueue.in([size, contact], contacts_queue)
    new_state = Map.put(state, :contacts_queue, new_contacts_queue)
    new_state
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

  defp channel_setup(channel, respondent, token, not_before, not_after) do
    try do
      Ask.Runtime.Channel.setup(channel, respondent, token, not_before, not_after)
    rescue
      _ ->
        Ask.Runtime.Channel.setup(
          Ask.Channel.runtime_channel(channel),
          respondent,
          token,
          not_before,
          not_after
        )
    end
  end

  defp channel_ask(channel, respondent, token, reply) do
    try do
      Ask.Runtime.Channel.ask(channel, respondent, token, reply)
    rescue
      _ -> Ask.Runtime.Channel.ask(Ask.Channel.runtime_channel(channel), respondent, token, reply)
    end
  end

  def activate_contact(
        %{
          active_contacts: active_contacts,
          contacts_queue: contacts_queue
        } = state
      ) do
    {{_unqueue_res, [size, unqueued_item]}, new_contacts_queue} = :pqueue.out(contacts_queue)
    state = Map.put(state, :active_contacts, active_contacts + size)
    state = Map.put(state, :contacts_queue, new_contacts_queue)

    {state, unqueued_item}
  end

  def deactivate_contact(
        %{
          active_contacts: active_contacts
        } = state
      ) do
    # We decrease the counter, leaving it as a separate function just in case 
    # this could be more sophisticated
    state = Map.put(state, :active_contacts, active_contacts - 1)
    state
  end

  @impl true
  def handle_call(
        {:ask, channel, %{id: respondent_id} = respondent, token, reply},
        _from,
        %{channel_id: channel_id} = state
      ) do
    {end_state, reply} =
      if channel_provider(channel_id) == "nuntium" do
        state =
          queue_contact(
            state,
            {respondent, token, reply},
            length(NuntiumChannel.reply_to_messages(reply, nil, respondent_id))
          )

        if can_unqueue(state) do
          {new_state, unqueued_item} = activate_contact(state)
          {unq_respondent, unq_token, unq_reply} = unqueued_item

          {
            new_state,
            channel_ask(channel, unq_respondent, unq_token, unq_reply)
          }
        else
          {state, respondent}
        end
      else
        # No ask will be done for other providers, just in case we bypass the ask
        {
          state,
          channel_ask(channel, respondent, token, reply)
        }
      end

    {:reply, reply, end_state, @timeout}
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
        %{channel_id: channel_id} = state
      ) do
    new_state = state

    {end_state, setup_response} =
      if channel_provider(channel_id) == "verboice" do
        new_state = queue_contact(new_state, {respondent, token, not_before, not_after}, 1)
        # Upon setup, we only setup an active contact for verboice 
        if can_unqueue(new_state) do
          {new_state, unqueued_item} = activate_contact(new_state)
          {unq_respondent, unq_token, unq_not_before, unq_not_after} = unqueued_item

          {
            new_state,
            channel_setup(channel, unq_respondent, unq_token, unq_not_before, unq_not_after)
          }
        else
          {new_state, {:ok, %{verboice_call_id: 9999}}}
        end
      else
        # In nuntium, we just setup, the active contacts will increase upon :ask
        {
          state,
          channel_setup(channel, respondent, token, not_before, not_after)
        }
      end

    {:reply, setup_response, end_state, @timeout}
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
  def handle_call(
        {:callback_recieved, channel, respondent, respondent_state, provider},
        _from,
        state
      ) do
    {state, setup_response} =
      case provider do
        "verboice" ->
          case respondent_state do
            rs when rs in ["failed", "busy", "no-answer", "expired", "completed"] ->
              new_state = deactivate_contact(state)
              # For the verboice case we will setup the next in the queue
              # Should we do something with the setup response?
              # In this case isn't the result of a setup call but a queue processing.
              if can_unqueue(new_state) do
                {new_state, unqueued_item} = activate_contact(new_state)
                {unq_respondent, unq_token, unq_not_before, unq_not_after} = unqueued_item

                {
                  new_state,
                  channel_setup(channel, unq_respondent, unq_token, unq_not_before, unq_not_after)
                }
              else
                {new_state, {:error, %{verboice_call_id: -1}}}
              end

            _ ->
              {state, {:error, %{verboice_call_id: -1}}}
          end

        "nuntium" ->
          new_state = deactivate_contact(state)

          if can_unqueue(new_state) do
            {new_state, unqueued_item} = activate_contact(state)
            {unq_respondent, unq_token, unq_reply} = unqueued_item

            {
              new_state,
              channel_ask(channel, unq_respondent, unq_token, unq_reply)
            }
          else
            {new_state, respondent}
          end
      end

    {:reply, setup_response, state, @timeout}
  end

  @impl true
  def handle_info(:timeout, channel_id) do
    ChannelBrokerSupervisor.terminate_child(channel_id)
  end
end
