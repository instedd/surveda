defmodule Ask.Runtime.ChannelBrokerHistory do
  alias __MODULE__
  use Ask.Model
  alias Ask.Repo

  schema "channel_broker_history" do
    belongs_to(:channel, Ask.Channel)
    field(:instruction, :string)
    field :parameters, :map
    field :active_contacts, {:array, :integer}
    field :contacts_queue_ids, {:array, :integer}

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :channel_id,
      :instruction,
      :parameters,
      :active_contacts,
      :contacts_queue_ids
    ])
  end

  def insert(channel_id, instruction, parameters, active_contacts, contacts_queue_ids) do
    params = %{
      channel_id: channel_id,
      instruction: instruction,
      parameters: parameters,
      active_contacts: active_contacts,
      contacts_queue_ids: contacts_queue_ids
    }

    changeset = changeset(%ChannelBrokerHistory{}, params)

    Repo.insert!(changeset)
  end

  def save(
        channel_id,
        instruction,
        parameters,
        active_contacts,
        contacts_queue
      ) do
    new_active_contacts =
      Enum.map(
        active_contacts,
        fn {k, dict} ->
          k
        end
      )

    contacts_queue_ids =
      Enum.map(
        :pqueue.to_list(contacts_queue),
        fn [_, c] ->
          elem(c, 0).id
        end
      )

    try do
      insert(channel_id, instruction, parameters, new_active_contacts, contacts_queue_ids)
    rescue
      _ -> :ok
    end

    {:ok}
  end

  def fetch(channel_id) do
    query_res =
      from(cbr in "channel_broker_history",
        where: cbr.channel_id == ^channel_id,
        select: [:active_contacts, :contacts_queue_ids]
      )
      |> Repo.one()

    cqi = Map.get(query_res, :contacts_queue_ids)

    cts = Map.get(query_res, :active_contacts)

    %{active_contacts: cts, contacts_queue_ids: cqi}
  end

  def saved?(channel_id) do
    Repo.exists?(from(cbr in "channel_broker_history", where: cbr.channel_id == ^channel_id))
  end
end
