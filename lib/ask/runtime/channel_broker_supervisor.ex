defmodule Ask.Runtime.ChannelBrokerSupervisor do
  alias Ask.Runtime.{ChannelBroker, ChannelBrokerAgent, SurveyBroker}
  alias Ask.Config
  use DynamicSupervisor

  def start_link() do
    start_link([])
  end

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_child(channel_id, channel_type, settings) do
    cond do
      channel_id in Map.keys(ChannelBrokerAgent.get()) ->
        # If channel state is stored in the agent, recover it from there
        DynamicSupervisor.start_child(
          __MODULE__,
          child_spec(
            channel_id,
            channel_type,
            settings,
            ChannelBrokerAgent.get_channel_state(channel_id)
          )
        )

      ChannelBrokerAgent.is_in_db(channel_id) ->
        # If channel state is stored in the db, recover it from there
        cb_db = ChannelBrokerAgent.recover_from_db(channel_id)

        channel_state = %{
          channel_id: channel_id,
          capacity: Map.get(settings, "capacity", Config.default_channel_capacity()),
          contacts_queue: :pqueue.new(),
          active_contacts: Map.get(cb_db, :active_contacts),
          # We save to db again inmediately on restart.
          op_count: 1
        }

        res =
          DynamicSupervisor.start_child(
            __MODULE__,
            child_spec(channel_id, channel_type, settings, channel_state)
          )

        # recontact contacts in the queue
        SurveyBroker.recontact_queued_respondents(Map.get(cb_db, :contacts_queue_ids))
        res

      true ->
        # Else, start the broker from scratch
        DynamicSupervisor.start_child(__MODULE__, child_spec(channel_id, channel_type, settings))
    end
  end

  def terminate_child(nil), do: terminate_child(0)

  def terminate_child(channel_id) do
    pid = lookup_child(channel_id)

    if pid do
      DynamicSupervisor.terminate_child(__MODULE__, pid)
    else
      :ok
    end
  end

  defp lookup_child(channel_id) do
    case Registry.lookup(:channel_broker_registry, channel_id) do
      [{pid, nil}] ->
        pid

      _ ->
        nil
    end
  end

  defp child_spec(channel_id, channel_type, settings) do
    %{
      id: "channel_broker_#{channel_id}",
      start: {ChannelBroker, :start_link, [channel_id, channel_type, settings]}
    }
  end

  defp child_spec(channel_id, channel_type, settings, state) do
    %{
      id: "channel_broker_#{channel_id}",
      start: {ChannelBroker, :start_link, [channel_id, channel_type, settings, state]}
    }
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
