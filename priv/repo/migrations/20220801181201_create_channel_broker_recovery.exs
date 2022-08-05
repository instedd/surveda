defmodule Ask.Repo.Migrations.CreateChannelBrokerInfo do
  use Ecto.Migration

  def change do
    create table(:channel_broker_recovery) do
      add :channel_id, references(:channels)
      add :active_contacts, :map
      add :contacts_queue_ids, :json

      timestamps()
    end
  end
end
