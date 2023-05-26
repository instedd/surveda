# NOTE: channels without channel_id (used in some unit tests) share a single process (channel_id: 0)
defmodule Ask.Runtime.ChannelBroker do
  alias Ask.Runtime.ChannelBrokerSupervisor
  alias Ask.Runtime.ChannelBrokerAgent, as: Agent
  alias Ask.Runtime.ChannelBrokerState, as: State
  alias Ask.{Channel, Logger}
  import Ecto.Query
  alias Ask.Repo
  use GenServer

  # Public interface

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

  def prepare(channel_id, channel) do
    call(channel_id, {:prepare, channel})
  end

  def setup(channel_id, channel_type, respondent, token, not_before, not_after) do
    cast(channel_id, {:setup, channel_type, respondent, token, not_before, not_after})
  end

  def has_delivery_confirmation?(channel_id, channel) do
    call(channel_id, {:has_delivery_confirmation?, channel})
  end

  def ask(channel_id, channel_type, channel, respondent, token, reply) do
    cast(channel_id, {:ask, channel_type, channel, respondent, token, reply})
  end

  def has_queued_message?(channel_id, channel_type, channel, respondent_id) do
    call(channel_id, {:has_queued_message?, channel_type, channel, respondent_id})
  end

  def cancel_message(channel_id, channel_type, channel, respondent_id) do
    cast(channel_id, {:cancel_message, channel_type, channel, respondent_id})
  end

  def message_expired?(channel_id, channel_type, channel, respondent_id) do
    call(channel_id, {:message_expired?, channel_type, channel, respondent_id})
  end

  def check_status(channel_id, channel) do
    call(channel_id, {:check_status, channel})
  end

  def on_channel_settings_change(channel_id, settings) do
    cast(channel_id, {:on_channel_settings_change, settings})
  end

  def callback_received(channel_id, respondent, respondent_state, provider) do
    cast(channel_id, {:callback_received, respondent, respondent_state, provider})
  end

  def force_activate_respondent(channel_id, respondent_id, size \\ 1) do
    cast(channel_id, {:force_activate_respondent, respondent_id, size})
  end

  defp call(nil, message) do
    if Mix.env() == :test do
      call(0, message)
    else
      raise "Channels with channel_id=nil are only allowed in tests"
    end
  end

  defp call(channel_id, message) when is_integer(channel_id) do
    find_or_start_process(channel_id)
    |> GenServer.call(message)
  end

  defp call(channel_id, message) do
    {channel_id, _} = Integer.parse(channel_id)
    call(channel_id, message)
  end

  defp cast(nil, message) do
    if Mix.env() == :test do
      cast(0, message)
    else
      raise "Channels with channel_id=nil are only allowed in tests"
    end
  end

  defp cast(channel_id, message) when is_integer(channel_id) do
    find_or_start_process(channel_id)
    |> GenServer.cast(message)
  end

  defp cast(channel_id, message) do
    {channel_id, _} = Integer.parse(channel_id)
    cast(channel_id, message)
  end

  defp find_or_start_process(channel_id) do
    case Registry.lookup(:channel_broker_registry, channel_id) do
      [{pid, _}] ->
        pid

      [] ->
        {channel_type, settings} = set_channel(channel_id)
        # if Mix.env() == :test do
        #   # FIXME: makes sure that we load the runtime channel from the current
        #   # process so it will be available in ChannelAgent.
        #   Ask.Channel.runtime_channel(channel_id)
        # end
        {:ok, pid} = ChannelBrokerSupervisor.start_child(channel_id, channel_type, settings)
        pid
    end
  end

  # NOTE: what about IVR?
  defp set_channel(0), do: {"sms", %{}}

  defp set_channel(channel_id) do
    [channel_type, settings] =
      from(c in "channels",
        where: c.id == ^channel_id,
        select: [c.type, c.settings]
      )
      |> Repo.one!()

    settings =
      if settings do
        Poison.decode!(settings)
      else
        %{}
      end

    {channel_type, settings}
  end

  # Server (internal callbacks for public interface)

  @impl true
  def init([channel_id, channel_type, settings]) do
    info("init (new)", channel_id: channel_id, channel_type: channel_type, settings: settings)
    state = (Agent.recover_state(channel_id) || State.new(channel_id, settings))
    schedule_GC(channel_type, state)
    {:ok, state, State.process_timeout(state)}
  end

  @impl true
  def handle_cast({:ask, "sms", channel, respondent, token, reply}, state) do
    info("handle_cast[ask]",
      channel_type: "sms",
      channel_id: state.channel_id,
      respondent_id: respondent.id,
      token: token,
      reply: reply
    )

    contact = {respondent, token, reply}
    size = Ask.Runtime.Channel.messages_count(channel, respondent, nil, reply, state.channel_id)

    new_state =
      state
      |> State.queue_contact(contact, size)
      |> try_activate_next_queued_contact()
      |> Agent.save_state()
      |> debug()

    {:noreply, new_state, State.process_timeout(state)}
  end

  @impl true
  def handle_cast({:setup, "ivr", respondent, token, not_before, not_after}, state) do
    info("handle_cast[setup]",
      channel_type: "ivr",
      channel_id: state.channel_id,
      respondent_id: respondent.id,
      token: token,
      not_before: not_before,
      not_after: not_after
    )

    # queue contact and try to activate immediately
    contact = {respondent, token, not_before, not_after}

    new_state =
      state
      |> State.queue_contact(contact, 1)
      |> try_activate_next_queued_contact()
      |> Agent.save_state()
      |> debug()

    {:noreply, new_state, State.process_timeout(state)}
  end

  # FIXME: needed?!
  @impl true
  def handle_cast({:setup, "sms", _, _, _, _}, state) do
    # shouldn't happen, but just in case: a silent noop is enough
    {:noreply, state, State.process_timeout(state)}
  end

  @impl true
  def handle_cast({:cancel_message, channel_type, channel, respondent_id}, state) do
    info("handle_cast[cancel_message]",
      channel_type: channel_type,
      channel_id: state.channel_id,
      respondent_id: respondent_id
    )

    channel_state = State.get_channel_state(state, respondent_id)
    Ask.Runtime.Channel.cancel_message(channel, channel_state)

    new_state =
      state
      |> State.deactivate_contact(respondent_id)
      |> State.remove_from_queue(respondent_id)
      |> Agent.save_state()
      |> debug()

    {:noreply, new_state, State.process_timeout(state)}
  end

  @impl true
  def handle_cast({:callback_received, respondent, respondent_state, "verboice"}, state) do
    info("handle_cast[callback_received]",
      respondent_id: respondent.id,
      respondent_state: respondent_state,
      provider: "verboice",
      channel_id: state.channel_id
    )

    new_state =
      if respondent_state in ["failed", "busy", "no-answer", "expired", "completed"] do
        state
        |> State.deactivate_contact(respondent.id)
        |> try_activate_next_queued_contact()
      else
        state
        |> State.touch_last_contact(respondent.id)
      end
      |> Agent.save_state()
      |> debug()

    {:noreply, new_state, State.process_timeout(state)}
  end

  @impl true
  def handle_cast({:callback_received, respondent, respondent_state, "nuntium"}, state) do
    info("handle_cast[callback_received]",
      respondent_id: respondent.id,
      respondent_state: respondent_state,
      provider: "nuntium",
      channel_id: state.channel_id
    )

    new_state =
      state
      |> State.decrement_respondents_contacts(respondent.id, 1)
      |> try_activate_next_queued_contact()
      |> Agent.save_state()
      |> debug()

    {:noreply, new_state, State.process_timeout(state)}
  end

  @impl true
  def handle_cast({:force_activate_respondent, respondent_id, size}, state) do
    info("handle_cast[force_activate_respondent]", respondent_id: respondent_id, size: size)

    new_state =
      state
      |> State.increment_respondents_contacts(respondent_id, size)
      |> Agent.save_state()
      |> debug()

    {:noreply, new_state, State.process_timeout(state)}
  end

  @impl true
  def handle_cast({:on_channel_settings_change, settings}, state) do
    info("handle_cast[on_channel_settings_change]", settings: settings)
    new_state = State.put_capacity(state, Map.get(settings, "capacity")) |> debug()
    {:noreply, new_state, State.process_timeout(state)}
  end


  @impl true
  def handle_call({:prepare, channel}, _from, state) do
    info("handle_call[prepare]", channel_id: state.channel_id)
    reply = Ask.Runtime.Channel.prepare(channel)
    {:reply, reply, state, State.process_timeout(state)}
  end

  @impl true
  def handle_call({:has_delivery_confirmation?, channel}, _from, state) do
    info("handle_call[has_delivery_confirmation?]", channel_id: state.channel_id)
    reply = Ask.Runtime.Channel.has_delivery_confirmation?(channel)
    {:reply, reply, state, State.process_timeout(state)}
  end

  # @impl true
  def handle_call(
        {:has_queued_message?, _channel_type, %{has_queued_message: has_queued_message},
         _respondent_id},
        _from,
        state
      ) do
    info("handle_call[has_queued_message?]", has_queued_message: has_queued_message)
    {:reply, has_queued_message, state, State.process_timeout(state)}
  end

  @impl true
  def handle_call({:has_queued_message?, _channel_type, _channel, respondent_id}, _from, state) do
    info("handle_call[has_queued_message?]", respondent_id: respondent_id)
    reply = State.is_active(state, respondent_id) || State.is_queued(state, respondent_id)
    {:reply, reply, state, State.process_timeout(state)}
  end

  @impl true
  def handle_call({:message_expired?, channel_type, channel, respondent_id}, _from, state) do
    info("handle_call[message_expired?]",
      channel_type: channel_type,
      channel_id: state.channel_id,
      respondent_id: respondent_id
    )

    channel_state = State.get_channel_state(state, respondent_id)
    reply = Ask.Runtime.Channel.message_expired?(channel, channel_state)
    {:reply, reply, state, State.process_timeout(state)}
  end

  @impl true
  def handle_call({:check_status, channel}, _from, state) do
    info("handle_call[check_status]", channel_id: state.channel_id)
    reply = Ask.Runtime.Channel.check_status(channel)
    {:reply, reply, state, State.process_timeout(state)}
  end

  @impl true
  def handle_info(:timeout, %{channel_id: channel_id} = state) do
    info("handle_info[timeout]", channel_id: channel_id)

    if State.inactive?(state) do
      Agent.delete_state(state.channel_id)
    else
      Agent.save_state(state)
    end

    # NOTE: maybe return {:stop, "terminating idle channel-broker", nil}
    ChannelBrokerSupervisor.terminate_child(channel_id)
  end

  def handle_info({:collect_garbage, channel_type}, state) do
    info("handle_info[collect_garbage]", channel_type: channel_type, config: state.config)

    active_respondents =
      from(r in "respondents",
        where: r.id in ^Map.keys(state.active_contacts) and r.state == "active",
        select: r.id
      )
      |> Repo.all()

    new_state =
      state
      |> State.clean_inactive_respondents(active_respondents)
      |> State.clean_outdated_respondents(Channel.runtime_channel(state.channel_id))
      |> activate_contacts()
      |> Agent.save_state()
      |> debug()

    # schedule next run
    schedule_GC(channel_type, state)

    {:noreply, new_state, State.process_timeout(state)}
  end

  # Internals

  # Activates has many queued contacts as possible, until either the queue is
  # empty or the channel capacity is reached.
  defp activate_contacts(state) do
    info("activate_contacts", channel_id: state.channel_id)

    if State.can_unqueue(state) do
      state
      |> activate_next_queued_contact()
      |> activate_contacts()
    else
      state
    end
  end

  # Activates one queued contact if possible: at least one contact is waiting in
  # queue _and_ the channel capacity hasn't been reached, yet.
  defp try_activate_next_queued_contact(state) do
    if State.can_unqueue(state) do
      activate_next_queued_contact(state)
    else
      state
    end
  end

  # Activates the next queued contact. There must be at least one contact in
  # queue. It doesn't verify if the channel capacity has been reached!
  defp activate_next_queued_contact(state) do
    {new_state, unqueued_item} = State.activate_next_in_queue(state)

    case unqueued_item do
      {respondent, token, not_before, not_after} ->
        ivr_call(new_state, respondent, token, not_before, not_after)

      {respondent, token, reply} ->
        channel_ask(new_state, respondent, token, reply)
    end
  end

  # TODO: don't call when about to expire (not after > 1 minute ago)
  defp ivr_call(state, respondent, token, not_before, not_after) do
    {:ok, %{verboice_call_id: verboice_call_id}} =
      Channel.runtime_channel(state.channel_id)
      |> Ask.Runtime.Channel.setup(respondent, token, not_before, not_after)

    channel_state = %{"verboice_call_id" => verboice_call_id}
    info("put_channel_state", respondent_id: respondent.id, channel_state: channel_state)
    State.put_channel_state(state, respondent.id, channel_state)
  end

  defp channel_ask(state, respondent, token, reply) do
    runtime_channel = Channel.runtime_channel(state.channel_id)

    # FIXME: only needed for tests to pass
    runtime_channel
    |> Ask.Runtime.Channel.setup(respondent, token, nil, nil)

    {:ok, %{nuntium_token: nuntium_token}} =
      runtime_channel
      |> Ask.Runtime.Channel.ask(respondent, token, reply, state.channel_id)

    channel_state = %{"nuntium_token" => nuntium_token}
    info("put_channel_state", respondent_id: respondent.id, channel_state: channel_state)
    State.put_channel_state(state, respondent.id, channel_state)
  end

  # Don't schedule automatic GC runs in tests.
  if Mix.env() == :test do
    defp schedule_GC(_, _), do: nil
  else
    defp schedule_GC(channel_type, state) do
      interval = State.gc_interval(state)
      info("schedule_GC", channel_type: channel_type, interval: interval)
      Process.send_after(self(), {:collect_garbage, channel_type}, interval)
    end
  end

  defp info(name, options) do
    Logger.info(
      "ChannelBroker.#{name}:#{
        Enum.map(options, fn {key, value} -> " #{key}=#{inspect(value)}" end)
      }"
    )
  end

  defp debug(state) do
    Logger.debug(fn ->
      num_active = map_size(state.active_contacts)
      num_queued = :pqueue.len(state.contacts_queue)
      "ChannelBrokerState: channel=#{state.channel_id} active=#{num_active} queued=#{num_queued}"
    end)
    # Logger.debug("ChannelBrokerState: #{inspect(state)}")
    state
  end
end
