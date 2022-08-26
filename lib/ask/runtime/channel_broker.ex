defmodule Ask.Runtime.ChannelBroker do
  alias Ask.Runtime.{Channel, ChannelBrokerAgent, ChannelBrokerSupervisor, NuntiumChannel}
  alias Ask.Config
  import Ecto.Query
  alias Ask.Repo
  use GenServer

  # Channels without channel_id (used in some unit tests) share a single process (channel_id: 0)

  def start_link(channel_id, channel_type, settings) do
    name = via_tuple(channel_id)
    GenServer.start_link(__MODULE__, [channel_id, channel_type, settings], name: name)
  end

  def start_link(channel_id, channel_type, settings, status) do
    name = via_tuple(channel_id)
    GenServer.start_link(__MODULE__, [channel_id, channel_type, settings, status], name: name)
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

  def has_queued_message?(nil, channel_type, channel, respondent_id) do
    has_queued_message?(0, channel_type, channel, respondent_id)
  end

  def has_queued_message?(channel_id, channel_type, channel, respondent_id) do
    call_gen_server(channel_id, {:has_queued_message?, channel_type, channel, respondent_id})
  end

  def cancel_message(nil, channel, channel_type, respondent_id) do
    cancel_message(0, channel, channel_type, respondent_id)
  end

  def cancel_message(channel_id, channel_type, channel, respondent_id) do
    call_gen_server(channel_id, {:cancel_message, channel_type, channel, respondent_id})
  end

  def message_expired?(nil, channel_type, channel, respondent_id) do
    message_expired?(0, channel_type, channel, respondent_id)
  end

  def message_expired?(channel_id, channel_type, channel, respondent_id) do
    call_gen_server(channel_id, {:message_expired?, channel_type, channel, respondent_id})
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

  def callback_received(channel_id, respondent, respondent_state, provider) do
    call_gen_server(
      channel_id,
      {:callback_received, respondent, respondent_state, provider}
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
    [channel_type, settings] = Repo.one!(query)
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
          ivr_call(new_state, unq_channel, unq_respondent, unq_token, unq_not_before, unq_not_after)

        _ ->
          # TODO: test channels?
          IO.puts("Not implemented")
      end

      if can_unqueue(new_state), do: activate_contacts(channel_type, new_state), else: new_state
    else
      state
    end
  end

  defp ivr_call(state, channel, respondent, token, not_before, not_after) do
    case channel_setup(channel, respondent, token, not_before, not_after) do
      {:ok, verboice_call_id} ->
        set_verboice_call_id(state, respondent.id, verboice_call_id)
      _ ->
        state
    end
  end

  defp collect_garbage(channel_type, interval) do
    Process.send_after(self(), {:collect_garbage, channel_type}, interval)
  end

  defp timeout_from_config(%{shut_down_minutes: timeout_minutes} = _config) do
    timeout_minutes * 60_000
  end

  defp gc_interval_from_config(%{gc_interval_minutes: gc_interval_minutes} = _config) do
    gc_interval_minutes * 60_000
  end

  defp gc_timeout_from_config(%{gc_outdate_hours: gc_outdate_hours} = _config) do
    gc_outdate_hours * 60 * 60
  end

  # Server (callbacks)

  @impl true
  def init([channel_id, channel_type, settings]) do
    %{to_db_operations: op_count} = config = Config.channel_broker_config()
    gc_interval = gc_interval_from_config(config)
    collect_garbage(channel_type, gc_interval)
    {
      :ok,
      # The internal logic of the ChannelBroker relies on a state with the following shape:
      %{
        # Each ChannelBroker process manage the load of a single channel.
        channel_id: channel_id,
        # The maximum parallel contacts this channel shouldn't exceded.
        capacity: Map.get(settings, "capacity", Config.default_channel_capacity()),
        # A dictionary of active contacts with the following shape:
        #   %{respondent_id: active_contact}
        #     active_contact is a Map with the following keys:
        #      - contacts: quantity of contactas being currently managed by the channel
        #      - last_contact: timestamp of the last contact made
        #      - verboice_call_id: an external id provided by Verboice to allow following up the
        #         requested call.
        active_contacts: Map.new(),
        # A priority queue implemented using pqueue (https://github.com/okeuday/pqueue/).
        #   When a contact is queued, the received params are stored to be used when the time
        #     to make the contact comes.
        #   Each element has one of the following shape:
        #    - Verboice: {respondent, token, not_before, not_after, channel}
        #    - Nuntium: {respondent, token, reply, channel}
        contacts_queue: :pqueue.new(),
        # See Config.channel_broker_config() comments
        config: config,
        # Counter of how many internal operations left until this state will be saved to the DB
        op_count: op_count
      },
      timeout_from_config(config)
    }
  end

  @impl true
  def init([_channel_id, channel_type, _settings, %{config: config} = status]) do
    gc_interval = gc_interval_from_config(config)
    collect_garbage(channel_type, gc_interval)

    {
      :ok,
      status,
      timeout_from_config(config)
    }
  end

  def active_contacts(
        %{
          active_contacts: active_contacts
        } = _state
      ) do
    Enum.reduce(active_contacts, 0, fn {_r, %{contacts: contacts}}, acc -> contacts + acc end)
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

  defp is_queued(
    %{
      contacts_queue: contacts_queue
    } = _state,
    respondent_id
  ) do
    contacts_list = :pqueue.to_list(contacts_queue)
    ids = Enum.map(contacts_list, fn queued_item -> queued_respondent_id(queued_item) end)
    respondent_id in ids
  end

  defp is_active(
    %{
      active_contacts: active_contacts
    } = _state,
    respondent_id
  ) do
    respondent_id in Map.keys(active_contacts)
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

  defp queued_respondent_id(queued_item) do
    # No matter the contact type, the first element of the
    # unqueued item is the respondent
    elem(queued_item, 0).id
  end

  def clean_inexistent_respondents(
    %{
      active_contacts: active_contacts
    } = state) do
    # Respondents that failed could have active contacts waiting and don't exists anymore

    query = from r in "respondents",
              where: r.id in ^Map.keys(active_contacts) and r.state != "failed",
              select: r.id

    active_respondents = Repo.all(query)

    new_active_contacts =
      :maps.filter(
        fn respondent_id, _ ->
          respondent_id in active_respondents
        end,
        Map.get(state, :active_contacts)
      )

    new_state = Map.put(state, :active_contacts, new_active_contacts)
    new_state
  end

  defp clean_outdated_respondents(%{active_contacts: active_contacts, config: config} = state) do
    {:ok, now} = DateTime.now("Etc/UTC")

    new_active_contacts =
      :maps.filter(
        fn _, %{last_contact: last_contact} ->
          DateTime.diff(now, last_contact, :second) < gc_timeout_from_config(config)
        end,
        active_contacts
      )

    new_state = Map.put(state, :active_contacts, new_active_contacts)
    new_state
  end

  def save_to_agent(
        %{
          channel_id: channel_id,
          op_count: op_count,
          config: %{to_db_operations: to_db_operations}
        } = state
      ) do
    new_op_count =
      if op_count <= 1 do
        # If counter reached, persist
        ChannelBrokerAgent.save_channel_state(channel_id, state, true)
        to_db_operations
      else
        # else, just save in memory
        ChannelBrokerAgent.save_channel_state(channel_id, state, false)
        op_count - 1
      end

    Map.put(state, :op_count, new_op_count)
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
    new_state = save_to_agent(new_state)

    new_state
  end

  def activate_contact(
        %{
          contacts_queue: contacts_queue,
          active_contacts: active_contacts
        } = state
      ) do
    {{_unqueue_res, [size, unqueued_item]}, new_contacts_queue} = :pqueue.out(contacts_queue)
    state = Map.put(state, :contacts_queue, new_contacts_queue)

    respondent_id = queued_respondent_id(unqueued_item)

    respondent_contacts =
      if respondent_id in Map.keys(active_contacts) do
        %{contacts: contacts} = Map.get(active_contacts, respondent_id)
        contacts
      else
        0
      end

    new_active_contacts =
      Map.put(
        active_contacts,
        respondent_id,
        %{
          contacts: respondent_contacts + size,
          last_contact: elem(DateTime.now("Etc/UTC"), 1)
        }
      )

    state = Map.put(state, :active_contacts, new_active_contacts)
    state = save_to_agent(state)

    {state, unqueued_item}
  end

  def update_last_contact(
        %{
          active_contacts: active_contacts
        } = state,
        respondent_id
      ) do
    new_active_contacts =
      if respondent_id in Map.keys(active_contacts) do
        active_contact = Map.get(active_contacts, respondent_id)
          |> Map.put(:last_contact, elem(DateTime.now("Etc/UTC"), 1))

        Map.put(
          active_contacts,
          respondent_id,
          active_contact
        )
      else
        active_contacts
      end

    state = Map.put(state, :active_contacts, new_active_contacts)
    state
  end

  defp set_verboice_call_id(
        %{
          active_contacts: active_contacts
        } = state,
        respondent_id,
        verboice_call_id
      ) do
    new_active_contacts =
      if respondent_id in Map.keys(active_contacts) do
        active_contact = Map.get(active_contacts, respondent_id)
        |> Map.put(:verboice_call_id, verboice_call_id)

        Map.put(
          active_contacts,
          respondent_id,
          active_contact
        )
      else
        active_contacts
      end

    Map.put(state, :active_contacts, new_active_contacts)
  end

  defp get_verboice_call_id(
    %{
      active_contacts: active_contacts
    } = _state,
    respondent_id
  ) do
    if respondent_id in Map.keys(active_contacts) do
      active_contact = Map.get(active_contacts, respondent_id)
      Map.get(active_contact, :verboice_call_id)
    else
      nil
    end
  end

  defp deactivate_contact(
        %{
          active_contacts: active_contacts
        } = state,
        respondent_id
      ) do
    respondent_contacts =
      if respondent_id in Map.keys(active_contacts) do
        %{contacts: contacts} = Map.get(active_contacts, respondent_id)
        contacts
      else
        0
      end

    new_active_contacts =
      if respondent_contacts > 1 do
        active_contact = Map.get(active_contacts, respondent_id)
          |> Map.put(:contacts, respondent_contacts - 1)
          |> Map.put(:timestamp, elem(DateTime.now("Etc/UTC"), 1))
        Map.put(
          active_contacts,
          respondent_id,
          active_contact
        )
      else
        Map.delete(active_contacts, respondent_id)
      end

    new_state = Map.put(state, :active_contacts, new_active_contacts)
    new_state = save_to_agent(new_state)
    new_state
  end

  def remove_from_queue(
    %{
      contacts_queue: contacts_queue
    } = state,
    respondent_id
  ) do
    new_contacts_queue = :pqueue.new()
    n = :pqueue.len(contacts_queue)
    new_contacts_queue = remove_r_contacts(contacts_queue, respondent_id, new_contacts_queue, n)
    new_state = Map.put(state, :contacts_queue, new_contacts_queue)
    new_state
  end

  defp remove_r_contacts(contacts_queue, respondent_id, new_contacts_queue, n) when n > 0 do
    {{:value, [size, unqueued_item], priority}, contacts_queue} = :pqueue.pout(contacts_queue)
    new_contacts_queue = if respondent_id == queued_respondent_id(unqueued_item) do
      new_contacts_queue
    else
      :pqueue.in([size, unqueued_item], priority, new_contacts_queue)
    end
    remove_r_contacts(contacts_queue, respondent_id, new_contacts_queue, n - 1)
  end

  defp remove_r_contacts(_contacts_queue, _respondent_id, new_contacts_queue, 0) do
    new_contacts_queue
  end

  defp get_channel_state(channel_type, state, respondent_id) do
    if channel_type == "ivr" and is_active(state, respondent_id) do
      verboice_call_id = get_verboice_call_id(state, respondent_id)
      %{"verboice_call_id" => verboice_call_id}
    else
      %{}
    end
  end

  @impl true
  def handle_call(
        {:ask, "sms" = _channel_type, channel, %{id: respondent_id} = respondent, token, reply},
        _from,
        %{config: config} = state
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

    {:reply, :ok, end_state, timeout_from_config(config)}
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
        %{config: config} = state
      ) do
    new_state = state

    end_state =
      if channel_type == "ivr" do
        new_state =
          queue_contact(new_state, {respondent, token, not_before, not_after, channel}, 1)

        # Upon setup, we only setup an active contact for verboice
        if can_unqueue(new_state) do
          {new_state, unqueued_item} = activate_contact(new_state)
          {unq_respondent, unq_token, unq_not_before, unq_not_after, unq_channel} = unqueued_item

          ivr_call(new_state, unq_channel, unq_respondent, unq_token, unq_not_before, unq_not_after)
        else
          new_state
        end
      else
        # In nuntium, we just setup, the active contacts will increase upon :ask
        channel_setup(channel, respondent, token, not_before, not_after)
        new_state
      end

    {:reply, :ok, end_state, timeout_from_config(config)}
  end

  @impl true
  def handle_call({:prepare, channel}, _from, %{config: config} = state) do
    reply = Channel.prepare(channel)
    {:reply, reply, state, timeout_from_config(config)}
  end

  @impl true
  def handle_call({:has_delivery_confirmation?, channel}, _from, %{config: config} = state) do
    reply = Channel.has_delivery_confirmation?(channel)
    {:reply, reply, state, timeout_from_config(config)}
  end

  # @impl true
  def handle_call({:has_queued_message?, _channel_type, %{has_queued_message: has_queued_message}, _respondent_id}, _from, %{config: config} = state) do
    {:reply, has_queued_message, state, timeout_from_config(config)}
  end

  @impl true
  def handle_call({:has_queued_message?, _channel_type, _channel, respondent_id}, _from, %{config: config} = state) do
    reply = is_active(state, respondent_id) || is_queued(state, respondent_id)
    {:reply, reply, state, timeout_from_config(config)}
  end

  @impl true
  def handle_call({:cancel_message, channel_type, channel, respondent_id}, _from, %{config: config} = state) do
    channel_state = get_channel_state(channel_type, state, respondent_id)
    Channel.cancel_message(channel, channel_state)
    state = deactivate_contact(state, respondent_id)
    state = remove_from_queue(state, respondent_id)
    {:reply, :ok, state, timeout_from_config(config)}
  end

  @impl true
  def handle_call({:message_expired?, channel_type, channel, respondent_id}, _from, %{config: config} = state) do
    channel_state = get_channel_state(channel_type, state, respondent_id)
    reply = Channel.message_expired?(channel, channel_state)
    {:reply, reply, state, timeout_from_config(config)}
  end

  @impl true
  def handle_call({:check_status, channel}, _from, %{config: config} = state) do
    reply = Channel.check_status(channel)
    {:reply, reply, state, timeout_from_config(config)}
  end

  @impl true
  def handle_call(
        {:callback_received, respondent, respondent_state, provider},
        _from,
        %{config: config} = state
      ) do
    end_state =
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

                ivr_call(new_state, unq_channel, unq_respondent, unq_token, unq_not_before, unq_not_after)
              else
                new_state
              end

            _ ->
              # If the callback tells something else, we update respondant last notice time
              update_last_contact(state, respondent.id)
          end

        "nuntium" ->
          new_state = deactivate_contact(state, respondent.id)

          if can_unqueue(new_state) do
            {new_state, unqueued_item} = activate_contact(new_state)
            {unq_respondent, unq_token, unq_reply, unq_channel} = unqueued_item

            channel_ask(unq_channel, unq_respondent, unq_token, unq_reply)
            new_state
          else
            new_state
          end
      end

    {:reply, :ok, end_state, timeout_from_config(config)}
  end

  @impl true
  def handle_info(:timeout, %{channel_id: channel_id} = state) do
    ChannelBrokerAgent.save_channel_state(channel_id, state, true)
    ChannelBrokerSupervisor.terminate_child(channel_id)
  end

  def handle_info({:collect_garbage, channel_type}, %{config: config} = state) do
    # Remove the garbage contacts from active
    # New versions of elixir has Maps.filter, replace when possible
    new_state = clean_inexistent_respondents(state)
      |> clean_outdated_respondents()

    # Activate new ones if possible
    new_state = activate_contacts(channel_type, new_state)
    # schedule next garbage collection
    gc_interval = gc_interval_from_config(config)
    collect_garbage(channel_type, gc_interval)
    {:noreply, new_state}
  end
end
