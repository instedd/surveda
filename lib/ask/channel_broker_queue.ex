defmodule Ask.ChannelBrokerQueue do
  use Ask.Model

  alias Ask.ChannelBrokerQueue, as: Queue
  alias Ask.Repo

  @primary_key false

  schema "channel_broker_queue" do
    belongs_to :channel, Ask.Channel, primary_key: true
    belongs_to :respondent, Ask.Respondent, primary_key: true

    # queued (pending):
    field :queued_at, :utc_datetime
    field :priority, Ecto.Enum, values: [low: 2, normal: 1, high: 0]
    field :size, :integer # number of outgoing messages (ivr=1, sms=1+)
    field :token, :string
    field :not_before, :utc_datetime
    field :not_after, :utc_datetime
    field :reply, Ask.Ecto.Type.ErlangTerm

    # sent (active):
    field :last_contact, :utc_datetime
    field :contacts, :integer # number of active messages left (pending confirmation)
    field :channel_state, Ask.Ecto.Type.ErlangTerm
  end

  def upsert!(params) do
    upsert_params =
      params
      |> Map.drop([:channel_id, :respondent_id])
      |> Map.put_new(:last_contact, nil)
      |> Map.put_new(:contacts, nil)
      |> Map.put_new(:channel_state, nil)
      |> Map.to_list()

    %Queue{}
    |> changeset(params)
    |> Repo.insert!(on_conflict: [set: upsert_params])
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :channel_id,
      :respondent_id,
      :queued_at,
      :priority,
      :size,
      :token,
      :not_before,
      :not_after,
      :reply,
      :last_contact,
      :contacts,
      :channel_state
    ])
    |> validate_required([
      :channel_id,
      :respondent_id,
      :queued_at,
      :priority,
      :size,
      :token
    ])
    # |> assoc_constraint(:channel, :respondent)
  end

  def activable_contacts?(channel_id) do
    # add leeway to activate contacts to be scheduled soon
    not_before = Ask.SystemTime.time().now |> DateTime.add(60, :second)

    Repo.exists?(from q in Queue,
      where: q.channel_id == ^channel_id and is_nil(q.last_contact) and (is_nil(q.not_before) or q.not_before <= ^not_before))
  end

  def count_active_contacts(channel_id) do
    Repo.one(from q in Queue,
      select: type(coalesce(sum(coalesce(q.contacts, 0)), 0), :integer),
      where: q.channel_id == ^channel_id and not(is_nil(q.last_contact)))
  end

  def queued_contacts(channel_id) do
    Repo.all(from q in Ask.ChannelBrokerQueue,
      where: q.channel_id == ^channel_id and is_nil(q.last_contact))
  end

  def active_contacts(channel_id) do
    Repo.all(from q in Ask.ChannelBrokerQueue,
      where: q.channel_id == ^channel_id and not(is_nil(q.last_contact)))
  end
end
