defmodule Ask.Runtime.ChannelBrokerState do
  import Ecto.Query

  alias Ask.{Config, Repo, SystemTime}
  alias Ask.ChannelBrokerQueue, as: Queue

  @enforce_keys [
    :channel_id,
    :capacity,
    :config
  ]

  defstruct [
    # Each ChannelBroker process manages a single channel.
    :channel_id,
    :channel_type,

    # Each ChannelBroker have the sole responsibility of interacting with their
    # Ask.Runtime.Channel
    :runtime_channel,

    # The maximum parallel contacts the channel shouldn't exceed.
    :capacity,

    # See `Config.channel_broker_config/0`
    :config
  ]

  def new(channel_id, channel_type, settings) do
    %Ask.Runtime.ChannelBrokerState{
      channel_id: channel_id,
      channel_type: channel_type,
      capacity: Map.get(settings, "capacity", Config.default_channel_capacity()),
      config: Config.channel_broker_config()
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

  # Returns true when there are neither active nor queued contacts (idle state).
  def inactive?(state) do
    !Repo.exists?(from q in Queue,
      where: q.channel_id == ^state.channel_id)
  end

  # Returns true if a respondent is currently in queue (active or not).
  def queued_or_active?(state, respondent_id) do
    Repo.exists?(from q in Queue,
      where: q.channel_id == ^state.channel_id and q.respondent_id == ^respondent_id)
  end

  # Adds a contact to the queue. The priority is set from the respondent's
  # disposition.
  def queue_contact(state, contact, size) do
    respondent = elem(contact, 0)

    if respondent.disposition == :queued do
      queue_contact(state, contact, size, :normal)
    else
      queue_contact(state, contact, size, :high)
    end
  end

  # Adds an IVR contact to the queue with given priority (`:high`, `:normal`, `:low`).
  def queue_contact(state, {respondent, token, not_before, not_after}, size, priority) do
    Queue.upsert!(%{
      channel_id: state.channel_id,
      respondent_id: respondent.id,
      queued_at: SystemTime.time().now,
      priority: priority,
      size: size,
      token: token,
      not_before: not_before,
      not_after: not_after,
      reply: nil,
    })
    state
  end

  # Adds an SMS contact to the queue with given priority (`:high`, `:normal`, `:low`).
  def queue_contact(state, {respondent, token, reply}, size, priority) do
    Queue.upsert!(%{
      channel_id: state.channel_id,
      respondent_id: respondent.id,
      queued_at: SystemTime.time().now,
      priority: priority,
      size: size,
      token: token,
      not_before: nil,
      not_after: nil,
      reply: reply,
    })
    state
  end

  def put_channel_state(state, respondent_id, channel_state) do
    query = from q in Queue,
      where: q.channel_id == ^state.channel_id and q.respondent_id == ^respondent_id
    Repo.update_all(query, set: [channel_state: channel_state])
    state
  end

  def get_channel_state(state, respondent_id) do
    channel_state = Repo.one(from q in Queue,
      select: q.channel_state,
      where: q.channel_id == ^state.channel_id and q.respondent_id == ^respondent_id)
    channel_state || %{}
  end

  # Touches the `last_contact` attribute for a respondent. Assumes that the
  # respondent has already been contacted. Does nothing if the respondent can't
  # be found.
  def touch_last_contact(state, respondent_id) do
    query = from q in Queue,
      where: q.channel_id == ^state.channel_id and q.respondent_id == ^respondent_id
    Repo.update_all(query, set: [last_contact: SystemTime.time().now])
    state
  end

  # Activates the next contact from the queue. There must be at least one
  # contact currently waiting in queue!
  def activate_next_in_queue(state) do
    # add leeway to activate contacts to be scheduled soon:
    not_before = SystemTime.time().now |> DateTime.add(60, :second)

    contact = Repo.one!(from q in Queue,
      where: q.channel_id == ^state.channel_id and is_nil(q.last_contact) and (q.not_before <= ^not_before or is_nil(q.not_before)),
      order_by: [q.priority, q.queued_at],
      preload: [:respondent],
      limit: 1
    )

    contact
    |> Queue.changeset(%{
      contacts: contact.size,
      last_contact: SystemTime.time().now
    })
    |> Repo.update()

    {state, to_item(state.channel_type, contact)}
  end

  defp to_item("ivr", contact) do
    {contact.respondent, contact.token, contact.not_before, contact.not_after}
  end

  defp to_item("sms", contact) do
    {contact.respondent, contact.token, contact.reply}
  end

  # Increments the number of contacts for the respondent. Activates the contact
  # if it wasn't already.
  def increment_respondents_contacts(state, respondent_id, size) do
    query = from q in Queue,
      update: [set: [
        contacts: coalesce(q.contacts, 0) + ^size,
        last_contact: ^SystemTime.time().now,
      ]],
      where: q.channel_id == ^state.channel_id and q.respondent_id == ^respondent_id
    Repo.update_all(query, [])

    state
  end

  # Decrements the number of contacts for the respondent. Does nothing if the
  # respondent isn't an active contact. Deactivates the respondent if the number
  # of contacts falls down to zero.
  def decrement_respondents_contacts(state, respondent_id, size) do
    query = from q in Queue,
      update: [set: [
        contacts: coalesce(q.contacts, 0) - ^size,
        last_contact: ^SystemTime.time().now,
      ]],
      where: q.channel_id == ^state.channel_id and q.respondent_id == ^respondent_id
    Repo.update_all(query, [])

    Repo.delete_all(from q in Queue,
      where: q.channel_id == ^state.channel_id and q.respondent_id == ^respondent_id and not(is_nil(q.contacts)) and q.contacts <= 0)

    state
  end

  # Deactivates a contact and removes them from the queue.
  def deactivate_contact(state, respondent_id) do
    Repo.delete_all(from q in Queue,
      where: q.channel_id == ^state.channel_id and q.respondent_id == ^respondent_id)
    state
  end

  # Deactivates a contact and puts them back into the queue.
  def reenqueue_contact(state, respondent_id, priority \\ :normal) do
    query = from q in Queue,
      where: q.channel_id == ^state.channel_id and q.respondent_id == ^respondent_id
    Repo.update_all(query, set: [
      queued_at: SystemTime.time().now,
      priority: priority,
      contacts: nil,
      last_contact: nil,
      channel_state: nil,
    ])
    state
  end

  # Returns true if we can active a new contact: there are pending contacts in
  # queue that we can activate, and the channel is under capacity.
  def can_unqueue(state) do
    if Queue.activable_contacts?(state.channel_id) do
      under_capacity?(state)
    else
      false
    end
  end

  # OPTIMIZE: Cache the number of active contacts into the state to heavily
  #           reduce the number of COUNT(*) queries that tend to be slow.
  #
  #           on load: count from the database & cache the value
  #           on activate: increment the number (by size)
  #           on increment/decrement/deactivate/reenqueue: update the count
  defp under_capacity?(state) do
    Queue.count_active_contacts(state.channel_id) < state.capacity
  end

  def active_respondent_ids(state) do
    Repo.all(from q in Queue,
      select: q.respondent_id,
      where: q.channel_id == ^state.channel_id and not(is_nil(q.last_contact)))
  end

  # Keep only the contacts for active respondents.
  #
  # Respondents that failed could have active contacts in Surveda, despite being
  # failed on the provider.
  #
  # FIXME: understand why Surveda would know about a contact having failed but
  #        the channel broker wouldn't have been notified?!
  def clean_inactive_respondents(state, active_respondent_ids) do
    Repo.delete_all(from q in Queue,
      where: q.channel_id == ^state.channel_id and not(q.respondent_id in(^active_respondent_ids)) and not(is_nil(q.last_contact)))

    state
  end

  # For idle contacts, we ask the remote channel for the actual IVR call or SMS
  # message state. Keep only the contacts that are active or queued.
  #
  # FIXME: this may take a while, and during that time the channel broker
  #        won't process its mailbox, if it ever becomes a problem, we might
  #        consider:
  #
  #        - only process a random N number of idle contacts on each call
  #        - run the task in its own concurrent process
  def clean_outdated_respondents(state) do
    idle_time = gc_allowed_idle_time(state)
    last_contact = SystemTime.time().now |> DateTime.add(-idle_time, :second)

    query = from q in Queue,
      select: [:channel_id, :respondent_id, :channel_state],
      where: q.channel_id == ^state.channel_id and q.last_contact < ^last_contact

    Repo.all(query) |> Enum.each(fn active_contact ->
      if Ask.Runtime.Channel.message_inactive?(state.runtime_channel, active_contact.channel_state) do
        Repo.delete(active_contact)
      end
    end)

    state
  end

  def statistics(state) do
    queued = Repo.all(from q in Queue,
      select: {q.priority, count()},
      where: is_nil(q.last_contact),
      group_by: q.priority)

    [
      channel: state.channel_id,
      active: Queue.count_active_contacts(state.channel_id),
      queued: Enum.reduce(queued, 0, fn {_, count}, a-> a + count end),
      queued_low: queued[:low] || 0,
      queued_normal: queued[:normal] || 0,
      queued_high: queued[:high] || 0,
    ]
  end
end
