defmodule Ask.Runtime.ChannelBroker do
  alias Ask.Runtime.{Channel, ChannelBrokerSupervisor, NuntiumChannel}
  alias Ask.Config
  import Ecto.Query
  alias Ask.Repo
  use GenServer

  @timeout_minutes 5
  @timeout @timeout_minutes * 60_000
  # collect garbage every hour
  @collect 60 * 60
  # consider garbage contacts with more than one day
  @collect_timeout 24 * 60 * 60

  # Channels without channel_id (for testing or simulation) share a single process (channel_id: 0)

  # def start_link(nil), do: start_link([0, "sms", %{}])

  def start_link(channel_id, channel_type \\ "sms", settings) do
    name = via_tuple(channel_id)
    GenServer.start_link(__MODULE__, [channel_id, channel_type, settings], name: name)
  end

  # Inspired by: https://medium.com/elixirlabs/registry-in-elixir-1-4-0-d6750fb5aeb
  defp via_tuple(channel_id) do
    {:via, Registry, {:channel_broker_registry, channel_id}}
  end

  def prepare(nil, channel), do: prepare(0, channel)

  def prepare(channel_id, channel) do
    call_gen_server(channel_id, {:prepare, channel})
  end

  def setup(nil, channel_type, channel, respondent, token, not_before, not_after) do
    setup(0, channel_type, channel, respondent, token, not_before, not_after)
  end

  def setup(channel_id, channel_type, channel, respondent, token, not_before, not_after) do
    call_gen_server(channel_id, {:setup, channel_type, channel, respondent, token, not_before, not_after})
  end

  def has_delivery_confirmation?(nil, channel), do: has_delivery_confirmation?(0, channel)

  def has_delivery_confirmation?(channel_id, channel) do
    call_gen_server(channel_id, {:has_delivery_confirmation?, channel})
  end

  def ask(nil, channel_type, channel, respondent, token, reply), do: ask(0, channel_type, channel, respondent, token, reply)

  def ask(channel_id, channel_type, channel, respondent, token, reply) do
    call_gen_server(channel_id, {:ask, channel_type, channel, respondent, token, reply})
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
    call_gen_server(
      channel_id,
      {:callback_recieved, respondent, respondent_state, provider}
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
        {channel_type, settings} = set_channel(channel_id)
        {:ok, pid} = ChannelBrokerSupervisor.start_child(channel_id, channel_type, settings)
        pid
    end
  end

  defp set_channel(0), do: {"sms", %{}}

  defp set_channel(channel_id) do
    query = from c in "channels", where: c.id == ^channel_id, select: [c.type, c.settings]
    [channel_type, settings] = Repo.one(query)
    settings = if settings do
      Poison.decode!(settings)
    else
      %{}
    end
    {channel_type, settings}
  end

  defp activate_contacts(channel_type, state) do
    if can_unqueue(state) do
      {new_state, unqueued_item} = activate_contact(state)

      case channel_type do
        "sms" ->
          {unq_respondent, unq_token, unq_reply, unq_channel} = unqueued_item
          channel_ask(unq_channel, unq_respondent, unq_token, unq_reply)

        "ivr" ->
          {unq_respondent, unq_token, unq_not_before, unq_not_after, unq_channel} = unqueued_item
          channel_setup(unq_channel, unq_respondent, unq_token, unq_not_before, unq_not_after)

        _ ->
          # TODO: test channels?
          IO.puts("Not implemented")
      end

      if can_unqueue(new_state), do: activate_contacts(channel_type, new_state), else: new_state
    else
      state
    end
  end

  defp collect_garbage(channel_type) do
    Process.send_after(self(), {:collect_garbage, channel_type}, @collect)
  end

  # Server (callbacks)

  @impl true
  def init([channel_id, channel_type, settings]) do
    collect_garbage(channel_type)

    {
      :ok,
      %{
        channel_id: channel_id,
        capacity: Map.get(settings, :capacity, Config.default_channel_capacity()),
        contact_timestamps: Map.new(),
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
    priority = if elem(contact, 0).disposition == :queued, do: 2, else: 1
    new_contacts_queue = :pqueue.in([size, contact], priority, contacts_queue)
    new_state = Map.put(state, :contacts_queue, new_contacts_queue)
    new_state
  end

  def active_contacts(
        %{
          contact_timestamps: contact_timestamps
        } = _state
      ) do
    Enum.reduce(contact_timestamps, 0, fn {_r, {c, _d}}, acc -> c + acc end)
  end

  def can_unqueue(
        %{
          capacity: capacity,
          contacts_queue: contacts_queue
        } = state
      ) do
    cond do
      :pqueue.is_empty(contacts_queue) -> false
      active_contacts(state) >= capacity -> false
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
          contacts_queue: contacts_queue,
          contact_timestamps: contact_timestamps
        } = state
      ) do
    {{_unqueue_res, [size, unqueued_item]}, new_contacts_queue} = :pqueue.out(contacts_queue)
    state = Map.put(state, :contacts_queue, new_contacts_queue)

    # No matter the contact type, the first element of the
    # unqueued item is the respondent
    respondent_id = elem(unqueued_item, 0).id

    respondent_contacts =
      if respondent_id in Map.keys(contact_timestamps) do
        elem(Map.get(contact_timestamps, respondent_id), 0)
      else
        0
      end

    new_contact_timestamps =
      Map.put(
        contact_timestamps,
        respondent_id,
        {
          respondent_contacts + size,
          elem(DateTime.now("Etc/UTC"), 1)
        }
      )

    state = Map.put(state, :contact_timestamps, new_contact_timestamps)

    {state, unqueued_item}
  end

  def update_last_contact(
        %{
          contact_timestamps: contact_timestamps
        } = state,
        respondent_id
      ) do
    new_contact_timestamps =
      if respondent_id in Map.keys(contact_timestamps) do
        respondent_contacts = elem(Map.get(contact_timestamps, respondent_id), 0)

        Map.put(
          contact_timestamps,
          respondent_id,
          {
            respondent_contacts,
            elem(DateTime.now("Etc/UTC"), 1)
          }
        )
      else
        contact_timestamps
      end

    state = Map.put(state, :contact_timestamps, new_contact_timestamps)
    state
  end

  def deactivate_contact(
        %{
          contact_timestamps: contact_timestamps
        } = state,
        respondent_id
      ) do
    respondent_contacts =
      if respondent_id in Map.keys(contact_timestamps) do
        elem(Map.get(contact_timestamps, respondent_id), 0)
      else
        0
      end

    new_contact_timestamps =
      if respondent_contacts > 1 do
        Map.put(
          contact_timestamps,
          respondent_id,
          {
            respondent_contacts - 1,
            elem(DateTime.now("Etc/UTC"), 1)
          }
        )
      else
        Map.delete(contact_timestamps, respondent_id)
      end

    new_state = Map.put(state, :contact_timestamps, new_contact_timestamps)
    new_state
  end

  @impl true
  def handle_call(
        {:ask, "sms" = _channel_type, channel, %{id: respondent_id} = respondent, token, reply},
        _from,
        state
      ) do
    new_state =
      queue_contact(
        state,
        {respondent, token, reply, channel},
        length(NuntiumChannel.reply_to_messages(reply, nil, respondent_id))
      )

    end_state = if can_unqueue(new_state) do
      {new_state, unqueued_item} = activate_contact(new_state)
      {unq_respondent, unq_token, unq_reply, unq_channel} = unqueued_item
      channel_ask(unq_channel, unq_respondent, unq_token, unq_reply)
      new_state
    else
      new_state
    end

    {:reply, :ok, end_state, @timeout}
  end

  @impl true
  def handle_call(
        {
          :setup,
          channel_type,
          channel,
          respondent,
          token,
          not_before,
          not_after
        },
        _from,
        state
      ) do
    new_state = state

    {end_state, setup_response} =
      if channel_type == "ivr" do
        new_state =
          queue_contact(new_state, {respondent, token, not_before, not_after, channel}, 1)

        # Upon setup, we only setup an active contact for verboice
        if can_unqueue(new_state) do
          {new_state, unqueued_item} = activate_contact(new_state)
          {unq_respondent, unq_token, unq_not_before, unq_not_after, unq_channel} = unqueued_item

          {
            new_state,
            channel_setup(unq_channel, unq_respondent, unq_token, unq_not_before, unq_not_after)
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
        {:callback_recieved, respondent, respondent_state, provider},
        _from,
        state
      ) do
    {end_state, setup_response} =
      case provider do
        "verboice" ->
          case respondent_state do
            rs when rs in ["failed", "busy", "no-answer", "expired", "completed"] ->
              # If the callback tells that the contact finished we deactivate the contact
              # and queue a new one if possible
              new_state = deactivate_contact(state, respondent.id)

              if can_unqueue(new_state) do
                {new_state, unqueued_item} = activate_contact(new_state)

                {unq_respondent, unq_token, unq_not_before, unq_not_after, unq_channel} =
                  unqueued_item

                {
                  new_state,
                  channel_setup(
                    unq_channel,
                    unq_respondent,
                    unq_token,
                    unq_not_before,
                    unq_not_after
                  )
                }
              else
                {new_state, {:ok, %{verboice_call_id: -1}}}
              end

            _ ->
              # If the callback tells something else, we update respondant last notice time
              new_state = update_last_contact(state, respondent.id)
              {new_state, {:ok, %{verboice_call_id: -1}}}
          end

        "nuntium" ->
          new_state = deactivate_contact(state, respondent.id)

          if can_unqueue(new_state) do
            {new_state, unqueued_item} = activate_contact(new_state)
            {unq_respondent, unq_token, unq_reply, unq_channel} = unqueued_item

            {
              new_state,
              channel_ask(unq_channel, unq_respondent, unq_token, unq_reply)
            }
          else
            {new_state, respondent}
          end
      end

    {:reply, setup_response, end_state, @timeout}
  end

  @impl true
  def handle_info(:timeout, channel_id) do
    ChannelBrokerSupervisor.terminate_child(channel_id)
  end

  def handle_info({:collect_garbage, channel_type}, %{contact_timestamps: contact_timestamps} = state) do
    {:ok, now} = DateTime.now("Etc/UTC")

    # Remove the garbage contacts from active
    # New versions of elixir has Maps.filter, replace when possible
    new_contact_timestamps =
      :maps.filter(
        fn _, {_, last_contact} ->
          DateTime.diff(now, last_contact, :second) < @collect_timeout
        end,
        contact_timestamps
      )

    new_state = Map.put(state, :contact_timestamps, new_contact_timestamps)

    # Activate new ones if possible
    new_state = activate_contacts(channel_type, new_state)

    # schedule next garbage collection
    collect_garbage(channel_type)
    {:noreply, new_state}
  end
end
