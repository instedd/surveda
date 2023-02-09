defmodule Ask.Repo.Migrations.ChannelBrokerRecoveryOnDelete do
  use Ecto.Migration

  def up do
    execute "ALTER TABLE channel_broker_recovery DROP FOREIGN KEY channel_broker_recovery_channel_id_fkey"

    alter table(:channel_broker_recovery) do
      modify :channel_id, references(:channels, on_delete: :delete_all)
    end
  end

  def down do
    execute "ALTER TABLE channel_broker_recovery DROP FOREIGN KEY channel_broker_recovery_channel_id_fkey"

    alter table(:channel_broker_recovery) do
      modify :channel_id, references(:channels)
    end
  end
end
