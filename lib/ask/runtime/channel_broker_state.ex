defmodule Ask.Runtime.ChannelBrokerState do
  alias Ask.{Config, PQueue, SystemTime}

  @enforce_keys [
    :channel_id,
    :capacity,
    :config
  ]

  defstruct [
    # Each ChannelBroker process manages a single channel.
    :channel_id,

    # Each ChannelBroker have the sole responsibility of interacting with their
    # Ask.Runtime.Channel
    :runtime_channel,

    # The maximum parallel contacts the channel shouldn't exceed.
    :capacity,

    # See `Config.channel_broker_config/0`
    :config,

    # A dictionary of active contacts with the following shape:
    # ```
    # %{respondent_id => %{
    #   contacts: Integer,
    #   last_contact: DateTime,
    #   channel_state: %{String.t => any()}
    # }}
    # ```
    #
    # Where:
    # - contacts: number of contacts being currently managed by the channel (ivr=1, sms=1+)
    # - last_contact: timestamp of the last sent contact or received callback
    # - channel_state: identifier(s) for the contact on the channel
    active_contacts: %{},

    # A priority queue.
    #
    # When a contact is queued, the received params are stored to be used when the time
    # to make the contact comes.
    #
    # Elements are tuples whose shape depend on the channel provider:
    # - Verboice: `{respondent, token, not_before, not_after}`
    # - Nuntium: `{respondent, token, reply}`
    contacts_queue: PQueue.new()
  ]

  def new(channel_id, settings) do
    config = Config.channel_broker_config()

    %Ask.Runtime.ChannelBrokerState{
      channel_id: channel_id,
      capacity: Map.get(settings, "capacity", Config.default_channel_capacity()),
      config: config
    }
  end

  def put_capacity(state, nil) do
    Map.put(state, :capacity, Config.default_channel_capacity())
  end

  def put_capacity(state, capacity) do
    Map.put(state, :capacity, capacity)
  end

  # TODO: should be in a ChannelBrokerConfig struct
  def process_timeout(state) do
    state.config.shut_down_minutes * 60_000
  end

  # TODO: should be in a ChannelBrokerConfig struct
  def gc_interval(state) do
    state.config.gc_interval_minutes * 60_000
  end

  # TODO: should be in a ChannelBrokerConfig struct
  def gc_allowed_idle_time(state) do
    state.config.gc_active_idle_minutes * 60
  end

  def is_active(state, respondent_id) do
    state.active_contacts
    |> Map.has_key?(respondent_id)
  end

  def put_channel_state(state, respondent_id, channel_state) do
    update_active_contact(state, respondent_id, fn active_contact ->
      Map.put(active_contact, :channel_state, channel_state)
    end)
  end

  def get_channel_state(state, respondent_id) do
    case Map.get(state.active_contacts, respondent_id) do
      %{channel_state: channel_state} -> channel_state
      # TODO: shall we raise instead?
      _ -> %{}
    end
  end

  # Adds a contact to the queue. The priority is set from the respondent's
  # disposition.
  def queue_contact(state, contact, size) do
    respondent = elem(contact, 0)
    priority = if respondent.disposition == :queued, do: :normal, else: :high
    queue_contact(state, contact, size, priority)
  end

  # Adds a contact to the queue with given priority (`:high`, `:normal`, `:low`).
  def queue_contact(state, contact, size, priority) do
    new_contacts_queue = PQueue.push(state.contacts_queue, [size, contact], priority)
    Map.put(state, :contacts_queue, new_contacts_queue)
  end

  # Updates the active contact for the respondent. Does nothing if there are
  # no active contact for this respondent.
  defp update_active_contact(%{active_contacts: active_contacts} = state, respondent_id, cb) do
    if active_contact = Map.get(active_contacts, respondent_id) do
      new_active_contacts = Map.put(active_contacts, respondent_id, cb.(active_contact))
      Map.put(state, :active_contacts, new_active_contacts)
    else
      state
    end
  end

  # Touches the :last_contact attribute for a respondent. Does nothing if the
  # respondent can't be found.
  def touch_last_contact(state, respondent_id) do
    update_active_contact(state, respondent_id, fn active_contact ->
      Map.put(active_contact, :last_contact, SystemTime.time().now)
    end)
  end

  # Activates the next contact from the queue. There must be at least one
  # contact currently waiting in queue!
  def activate_next_in_queue(%{active_contacts: active_contacts} = state) do
    {new_contacts_queue, [size, unqueued_item]} = PQueue.pop(state.contacts_queue)
    respondent_id = queued_respondent_id(unqueued_item)

    active_contact =
      active_contacts
      |> Map.get(respondent_id, %{contacts: 0})

    new_active_contact =
      active_contact
      |> Map.put(:contacts, active_contact.contacts + size)
      |> Map.put(:last_contact, SystemTime.time().now)

    new_active_contacts =
      active_contacts
      |> Map.put(respondent_id, new_active_contact)

    new_state =
      state
      |> Map.put(:contacts_queue, new_contacts_queue)
      |> Map.put(:active_contacts, new_active_contacts)

    {new_state, unqueued_item}
  end

  # Increments the number of contacts for the respondent. Activates the contact
  # if it wasn't already.
  def increment_respondents_contacts(
        %{active_contacts: active_contacts} = state,
        respondent_id,
        size
      ) do
    active_contact =
      active_contacts
      |> Map.get(respondent_id, %{contacts: 0})

    new_active_contact =
      active_contact
      |> Map.put(:contacts, active_contact.contacts + size)
      |> Map.put(:last_contact, SystemTime.time().now)

    new_active_contacts =
      active_contacts
      |> Map.put(respondent_id, new_active_contact)

    Map.put(state, :active_contacts, new_active_contacts)
  end

  # Decrements the number of contacts for the respondent. Does nothing if the
  # respondent isn't an active contact. Deactivates the respondent if the number
  # of contacts falls down to zero.
  def decrement_respondents_contacts(
        %{active_contacts: active_contacts} = state,
        respondent_id,
        size
      ) do
    active_contact =
      active_contacts
      |> Map.get(respondent_id)

    if active_contact do
      new_value = active_contact.contacts - size

      if new_value <= 0 do
        deactivate_contact(state, respondent_id)
      else
        new_active_contact =
          active_contact
          |> Map.put(:contacts, new_value)
          |> Map.put(:last_contact, SystemTime.time().now)

        new_active_contacts =
          active_contacts
          |> Map.put(respondent_id, new_active_contact)

        Map.put(state, :active_contacts, new_active_contacts)
      end
    else
      state
    end
  end

  def deactivate_contact(state, respondent_id) do
    respondent_contacts = contacts_for(state, respondent_id)

    if respondent_contacts > 1 do
      update_active_contact(state, respondent_id, fn active_contact ->
        active_contact
        |> Map.put(:contacts, respondent_contacts - 1)
        |> Map.put(:last_contact, SystemTime.time().now)
      end)
    else
      state
      |> Map.put(:active_contacts, Map.delete(state.active_contacts, respondent_id))
    end
  end

  # Returns the current number of active contacts for the respondent.
  defp contacts_for(state, respondent_id) do
    case Map.get(state.active_contacts, respondent_id) do
      %{contacts: contacts} -> contacts
      _ -> 0
    end
  end

  def can_unqueue(state) do
    cond do
      PQueue.empty?(state.contacts_queue) -> false
      activable_contacts?(state.contacts_queue) -> under_capacity?(state)
      true -> false
    end
  end

  defp activable_contacts?(queue) do
    PQueue.any?(queue, fn [_, item] ->
      case item do
        {_, _, not_before, _} -> Date.compare(not_before, SystemTime.time().now) != :gt
        _ -> true
      end
    end)
  end

  defp under_capacity?(state) do
    count_active_contacts(state) < state.capacity
  end

  defp count_active_contacts(state) do
    state.active_contacts
    |> Enum.reduce(0, fn {_, %{contacts: contacts}}, acc -> contacts + acc end)
  end

  def is_queued(state, respondent_id) do
    state.contacts_queue
    |> PQueue.any?(fn [_, item] -> queued_respondent_id(item) == respondent_id end)
  end

  def remove_from_queue(state, respondent_id) do
    new_contacts_queue =
      state.contacts_queue
      |> PQueue.delete(fn [_, item] -> queued_respondent_id(item) == respondent_id end)
    Map.put(state, :contacts_queue, new_contacts_queue)
  end

  # Keep only the contacts for active respondents.
  #
  # Respondents that failed could have active contacts in Surveda, despite being
  # failed on the provider.
  #
  # FIXME: understand why Surveda would know about a contact having failed but
  #        the channel broker wouldn't have been notified?!
  def clean_inactive_respondents(state, active_respondents) do
    # TODO: Elixir 1.13 has Map.filter/2
    new_active_contacts =
      :maps.filter(
        fn respondent_id, _ -> respondent_id in active_respondents end,
        state.active_contacts
      )

    Map.put(state, :active_contacts, new_active_contacts)
  end

  # For leftover active contacts, we ask the remote channel for the actual IVR
  # call or SMS message state. Keep only the contacts that are active or queued.
  def clean_outdated_respondents(state) do
    idle_time = gc_allowed_idle_time(state)
    now = SystemTime.time().now

    # TODO: Elixir 1.13 has Map.filter/2
    new_active_contacts =
      :maps.filter(
        fn _, %{last_contact: last_contact} = active_contact ->
          if DateTime.diff(now, last_contact, :second) < idle_time do
            true
          else
            !Ask.Runtime.Channel.message_inactive?(state.runtime_channel, active_contact.channel_state)
          end
        end,
        state.active_contacts
      )

    Map.put(state, :active_contacts, new_active_contacts)
  end

  defp queued_respondent_id(queued_item) do
    elem(queued_item, 0).id
  end

  # Returns true when there are neither active nor queued contacts (idle state).
  def inactive?(state) do
    map_size(state.active_contacts) == 0 && PQueue.empty?(state.contacts_queue)
  end
end
