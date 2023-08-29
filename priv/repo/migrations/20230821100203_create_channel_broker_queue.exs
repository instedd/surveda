defmodule Ask.Repo.Migrations.CreateChannelBrokerQueue do
  use Ecto.Migration

  def up do
    create table(:channel_broker_queue, primary_key: false) do
      add :channel_id, :"bigint unsigned", null: false, primary_key: true
      add :respondent_id, :"bigint unsigned", null: false, primary_key: true

      # queued (pending):
      add :queued_at, :utc_datetime, null: false
      add :priority, :tinyint, null: false
      add :size, :integer, null: false
      add :token, :string, null: false
      add :not_before, :utc_datetime
      add :not_after, :utc_datetime
      add :reply, :binary

      # sent (active):
      add :last_contact, :utc_datetime
      add :contacts, :integer
      add :channel_state, :binary
    end

    index(:channel_broker_queue, [:priority, :queued_at])
    index(:channel_broker_queue, [:not_before])
    index(:channel_broker_queue, [:last_contact])
  end

  def down do
    drop table(:channel_broker_queue)
  end
end
