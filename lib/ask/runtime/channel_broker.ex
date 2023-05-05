defmodule Ask.Runtime.ChannelBroker do
  alias Ask.Runtime.{ChannelBrokerAgent, ChannelBrokerSupervisor, NuntiumChannel}
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
    call_gen_server(channel_id, {:prepare, channel})
  end

  def setup(channel_id, channel_type, channel, respondent, token, not_before, not_after) do
    call_gen_server(
      channel_id,
      {:setup, channel_type, channel, respondent, token, not_before, not_after}
    )
  end

  def has_delivery_confirmation?(channel_id, channel) do
    call_gen_server(channel_id, {:has_delivery_confirmation?, channel})
  end

  def ask(channel_id, channel_type, channel, respondent, token, reply) do
    call_gen_server(channel_id, {:ask, channel_type, channel, respondent, token, reply})
  end

  def has_queued_message?(channel_id, channel_type, channel, respondent_id) do
    call_gen_server(channel_id, {:has_queued_message?, channel_type, channel, respondent_id})
  end

  def cancel_message(channel_id, channel_type, channel, respondent_id) do
    call_gen_server(channel_id, {:cancel_message, channel_type, channel, respondent_id})
  end

  def message_expired?(channel_id, channel_type, channel, respondent_id) do
    call_gen_server(channel_id, {:message_expired?, channel_type, channel, respondent_id})
  end

  def check_status(channel_id, channel) do
    call_gen_server(channel_id, {:check_status, channel})
  end

  def on_channel_settings_change(channel_id, settings) do
    call_gen_server(channel_id, {:on_channel_settings_change, settings})
  end

  def callback_received(channel_id, respondent, respondent_state, provider) do
    call_gen_server(channel_id, {:callback_received, respondent, respondent_state, provider})
  end

  def force_activate_respondent(channel_id, respondent_id) do
    call_gen_server(channel_id, {:force_activate_respondent, respondent_id})
  end

  # NOTE: channels without channel_id (used in some unit tests) share a single process (channel_id: 0)
  defp call_gen_server(nil, message) do
    if Mix.env() == :test do
      call_gen_server(0, message)
    else
      raise "Channels with channel_id=nil are only allowed in tests"
    end
  end

  defp call_gen_server(channel_id, message) when is_integer(channel_id) do
    find_or_start_process(channel_id)
    |> GenServer.call(message)
  end

  defp call_gen_server(channel_id, message) do
    {channel_id, _} = Integer.parse(channel_id)
    call_gen_server(channel_id, message)
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
    state = State.new(channel_id, settings)
    schedule_GC(channel_type, state)
    {:ok, state, State.process_timeout(state)}
  end

  @impl true
  def init([channel_id, channel_type, settings, state]) do
    info("init (state)", channel_id: channel_id, channel_type: channel_type, settings: settings)
    schedule_GC(channel_type, state)
    {:ok, state, State.process_timeout(state)}
  end

  @impl true
  def handle_call({:ask, "sms", channel, respondent, token, reply}, _from, state) do
    info("handle_call[ask]",
      channel_type: "sms",
      channel_id: state.channel_id,
      respondent_id: respondent.id,
      token: token,
      reply: reply
    )

    contact = {respondent, token, reply, channel}

    # FIXME: don't call NuntiumChannel directly!
    # OPTIMIZE: the call will generate the actual replies which we discard right
    #           away, we shall a Ask.Runtime.Channel. function instead (verboice
    #           would answer with hardcoded 1, and Nuntium count the number of
    #           replies to send).
    size =
      reply
      |> NuntiumChannel.reply_to_messages(nil, respondent.id, state.channel_id)
      |> length()

    new_state =
      state
      |> State.queue_contact(contact, size)
      |> try_activate_next_queued_contact()
      |> save_to_agent()
      |> debug()

    {:reply, :ok, new_state, State.process_timeout(state)}
  end

  @impl true
  def handle_call(
        {:setup, "ivr", channel, respondent, token, not_before, not_after},
        _from,
        state
      ) do
    info("handle_call[setup]",
      channel_type: "ivr",
      channel_id: state.channel_id,
      respondent_id: respondent.id,
      token: token,
      not_before: not_before,
      not_after: not_after
    )

    # queue contact and try to activate immediately
    contact = {respondent, token, not_before, not_after, channel}

    new_state =
      state
      |> State.queue_contact(contact, 1)
      |> try_activate_next_queued_contact()
      |> save_to_agent()
      |> debug()

    {:reply, :ok, new_state, State.process_timeout(state)}
  end

  @impl true
  def handle_call(
        {:setup, "sms", channel, respondent, token, not_before, not_after},
        _from,
        state
      ) do
    info("handle_call[setup]",
      channel_type: "sms",
      channel_id: state.channel_id,
      respondent_id: respondent.id,
      token: token,
      not_before: not_before,
      not_after: not_after
    )

    # only setup, contacts will be activated upon :ask
    channel_setup(channel, respondent, token, not_before, not_after)

    {:reply, :ok, state, State.process_timeout(state)}
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
  def handle_call({:cancel_message, channel_type, channel, respondent_id}, _from, state) do
    info("handle_call[cancel_message]",
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
      |> save_to_agent()
      |> debug()

    {:reply, :ok, new_state, State.process_timeout(state)}
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
  def handle_call({:callback_received, respondent, respondent_state, "verboice"}, _from, state) do
    info("handle_call[callback_received]",
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
      |> save_to_agent()
      |> debug()

    {:reply, :ok, new_state, State.process_timeout(state)}
  end

  @impl true
  def handle_call({:callback_received, respondent, respondent_state, "nuntium"}, _from, state) do
    info("handle_call[callback_received]",
      respondent_id: respondent.id,
      respondent_state: respondent_state,
      provider: "nuntium",
      channel_id: state.channel_id
    )

    new_state =
      state
      |> State.deactivate_contact(respondent.id)
      |> try_activate_next_queued_contact()
      |> save_to_agent()
      |> debug()

    {:reply, :ok, new_state, State.process_timeout(state)}
  end

  @impl true
  def handle_call({:force_activate_respondent, respondent_id}, _from, state) do
    info("handle_call[force_activate_respondent]", respondent_id: respondent_id)

    new_state =
      state
      |> State.increment_respondents_contacts(respondent_id, 1)
      |> save_to_agent()
      |> debug()

    {:reply, :ok, new_state, State.process_timeout(state)}
  end

  @impl true
  def handle_call({:on_channel_settings_change, settings}, _from, state) do
    info("handle_call[on_channel_settings_change]", settings: settings)
    new_state = State.put_capacity(state, Map.get(settings, "capacity")) |> debug()
    {:reply, :ok, new_state, State.process_timeout(state)}
  end

  @impl true
  def handle_info(
        :timeout,
        %{channel_id: channel_id, config: %{to_db_operations: to_db_operations}} = state
      ) do
    info("handle_info[timeout]", channel_id: channel_id, to_db_operations: to_db_operations)

    # save the state to the agent in DB only if it is enabled, otherwise just in memory
    ChannelBrokerAgent.save_channel_state(channel_id, state, to_db_operations > 0)
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

    runtime_channel =
      Channel
      |> Repo.get(state.channel_id)
      |> Channel.runtime_channel()

    new_state =
      state
      |> State.clean_inactive_respondents(active_respondents)
      |> State.clean_outdated_respondents(runtime_channel)
      |> activate_contacts()
      |> save_to_agent()
      |> debug()

    # schedule next run
    schedule_GC(channel_type, state)

    {:noreply, new_state}
  end

  # Internals

  defp channel_setup(%Channel{} = channel, respondent, token, not_before, not_after) do
    channel
    |> Channel.runtime_channel()
    |> channel_setup(respondent, token, not_before, not_after)
  end

  defp channel_setup(runtime_channel, respondent, token, not_before, not_after) do
    runtime_channel
    |> Ask.Runtime.Channel.setup(respondent, token, not_before, not_after)
  end

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

  # Activates the next queued contact. There must be one at least one contact in
  # queue, and doesn't verify if the channel capacity has been reached!
  defp activate_next_queued_contact(state) do
    {new_state, unqueued_item} = State.activate_next_in_queue(state)

    case unqueued_item do
      {respondent, token, not_before, not_after, channel} ->
        ivr_call(new_state, channel, respondent, token, not_before, not_after)

      {respondent, token, reply, channel} ->
        channel_ask(new_state, channel, respondent, token, reply, state.channel_id)
    end
  end

  defp ivr_call(state, channel, respondent, token, not_before, not_after) do
    {:ok, %{verboice_call_id: verboice_call_id}} =
      channel_setup(channel, respondent, token, not_before, not_after)

    channel_state = %{"verboice_call_id" => verboice_call_id}
    info("put_channel_state", respondent_id: respondent.id, channel_state: channel_state)
    State.put_channel_state(state, respondent.id, channel_state)
  end

  defp channel_ask(state, %Channel{} = channel, respondent, token, reply, channel_id) do
    runtime_channel = Channel.runtime_channel(channel)
    channel_ask(state, runtime_channel, respondent, token, reply, channel_id)
  end

  defp channel_ask(
         state,
         runtime_channel,
         %{id: respondent_id} = respondent,
         token,
         reply,
         channel_id
       ) do
    {:ok, %{nuntium_token: nuntium_token}} =
      Ask.Runtime.Channel.ask(runtime_channel, respondent, token, reply, channel_id)

    channel_state = %{"nuntium_token" => nuntium_token}
    info("put_channel_state", respondent_id: respondent_id, channel_state: channel_state)
    State.put_channel_state(state, respondent.id, channel_state)
  end

  # NOTE: save to agent and persist to DB are disabled for now.
  # FIXME: only persist to DB should be disabled!
  defp save_to_agent(%{op_count: op_count, config: %{to_db_operations: to_db_operations}} = state) do
    # only persist to DB when the counter is reached
    new_op_count =
      if op_count <= 1 and to_db_operations > 0 do
        ChannelBrokerAgent.save_channel_state(state.channel_id, state, true)
        to_db_operations
      else
        ChannelBrokerAgent.save_channel_state(state.channel_id, state, false)
        op_count - 1
      end

    Map.put(state, :op_count, new_op_count)
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
    Logger.debug("CHNL_BRK state: #{inspect(state)}")
    state
  end
end
