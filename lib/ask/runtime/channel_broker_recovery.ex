defmodule Ask.Runtime.ChannelBrokerRecovery do
  alias __MODULE__
  use Ask.Model
  alias Ask.Repo

  schema "channel_broker_recovery" do
    belongs_to(:channel, Ask.Channel)
    field(:active_contacts, :map)
    field :contacts_queue_ids, Ask.Ecto.Type.JSON

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:channel_id, :active_contacts, :contacts_queue_ids])
  end

  def upsert(%{
    channel_id: channel_id,
    active_contacts: active_contacts,
    contacts_queue_ids: contacts_queue_ids
  } = params) do
    changeset = changeset(%ChannelBrokerRecovery{}, params)
    Repo.insert!(changeset, on_conflict: [set: [
      # channel_id: channel_id,
      active_contacts: active_contacts,
      contacts_queue_ids: contacts_queue_ids
    ]])
  end

  def save(%{
      channel_id: channel_id,
      active_contacts: active_contacts,
      contacts_queue: contacts_queue
    } = state) do
    new_active_contacts =
      Enum.map(
        active_contacts,
        fn {k, dict} -> {k, Map.put(dict, :last_contact, DateTime.to_string(Map.get(dict, :last_contact)))} end
      ) |> Map.new()

    contacts_queue_ids =
      Enum.map(
        :pqueue.to_list(contacts_queue),
        fn [_, c] ->
          elem(c, 0).id
        end
      )

    params = %{
      channel_id: channel_id,
      active_contacts: new_active_contacts,
      contacts_queue_ids: contacts_queue_ids
    }

    upsert(params)

    state
  end

  def fetch(channel_id) do
    query_res =
      from(cbr in "channel_broker_recovery",
        where: cbr.channel_id == ^channel_id,
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

  def saved?(channel_id) do
    Repo.exists?(from(cbr in "channel_broker_recovery", where: cbr.channel_id == ^channel_id))
  end
end
