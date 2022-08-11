defmodule Ask.Runtime.ChannelBrokerAgent do
  alias Ask.Repo

  use Agent
  use Ask.Model

  schema "channel_broker_recovery" do
    belongs_to(:channel, Ask.Channel)
    field(:active_contacts, :map)

    timestamps()
  end

  def start_link do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def get do
    Agent.get(__MODULE__, & &1)
  end

  def get_channel_state(channel_id) do
    Map.get(Agent.get(__MODULE__, & &1), channel_id)
  end

  def update do
    Agent.update(__MODULE__, & &1)
  end

  def save_channel_state(channel_id, state, persist) do
    Agent.update(__MODULE__, fn s -> Map.put(s, channel_id, state) end)

    if persist do
      persist_to_db(channel_id)
    end
  end

  def persist_to_db(channel_id) do
    channel_state = get_channel_state(channel_id)

    new_active_contacts =
      Enum.map(
        Map.get(channel_state, :active_contacts),
        fn {k, dict} -> {k, Map.put(dict, :last_contact, DateTime.to_string(Map.get(dict, :last_contact)))} end
      ) |> Map.new()

      contacts_queue_ids =
      Enum.map(
        :pqueue.to_list(Map.get(channel_state, :contacts_queue)),
        fn [_, c] ->
          elem(c, 0).id
        end
      )

    from(cbi in "channel_broker_recovery", where: cbi.channel_id == ^channel_id) |> Repo.delete_all()

    if channel_id in Map.keys(get()) do
      Repo.insert_all(
        "channel_broker_recovery",
        [
          %{
            channel_id: channel_id,
            active_contacts: new_active_contacts,
            contacts_queue_ids: contacts_queue_ids,
            inserted_at: DateTime.utc_now(),
            updated_at: DateTime.utc_now()
          }
        ]
      )
    end
  end

  def recover_from_db(channel_id) do
    query_res =
      from(cbi in "channel_broker_recovery",
        where: cbi.channel_id == ^channel_id,
        select: [:active_contacts, :contacts_queue_ids]
      )
      |> Repo.one()

    cqi = Map.get(query_res, :contacts_queue_ids)

    cts =
      Enum.map(
        Map.get(query_res, :active_contacts),
        fn {k, dict} ->
          new_dict = dict |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
          new_lc =
            try do
              {:ok, new_lc} = Jason.decode(Map.get(new_dict, :last_contact))
              new_lc
            rescue
              _ -> Map.get(new_dict, :last_contact)
            end

          {new_k, _} = Integer.parse(k)
          {:ok, new_lc_decoded, 0} = DateTime.from_iso8601(new_lc)
          {new_k, Map.put(new_dict, :last_contact, new_lc_decoded)}
        end
      ) |> Map.new()

    %{active_contacts: cts, contacts_queue_ids: cqi}
  end

  def is_in_db(channel_id) do
    count =
      from(cbi in "channel_broker_recovery", where: cbi.channel_id == ^channel_id, select: count("*"))
      |> Repo.one()

    count != 0
  end
end
