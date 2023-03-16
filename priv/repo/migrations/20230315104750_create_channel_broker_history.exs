defmodule Ask.Repo.Migrations.CreateChannelBrokerHistory do
  use Ecto.Migration

  def change do
    create table(:channel_broker_history) do
      add :channel_id, references(:channels)
      add :instruction, :string
      add :parameters, :json
      add :active_contacts, :json
      add :contacts_queue_ids, :json

      timestamps()
    end
  end
end
