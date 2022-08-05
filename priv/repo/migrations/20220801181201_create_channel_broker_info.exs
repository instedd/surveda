defmodule Ask.Repo.Migrations.CreateChannelBrokerInfo do
  use Ecto.Migration

  def change do
    create table(:channel_broker_info) do
      add :channel_id, references(:channels)
      add :contact_timestamps, :map
      add :contacts_queue_ids, :json

      timestamps()
    end
  end
end
