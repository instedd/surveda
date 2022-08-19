defmodule Ask.Repo.Migrations.AddChannelIdUniqueIndex do
  use Ecto.Migration

  def up do
    create unique_index(:channel_broker_recovery, :channel_id)
  end

  def down do
  end
end
