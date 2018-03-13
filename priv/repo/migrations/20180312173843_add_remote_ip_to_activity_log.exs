defmodule Ask.Repo.Migrations.AddRemoteIpToActivityLog do
  use Ecto.Migration

  def up do
    alter table(:activity_log) do
      add :remote_ip, :string
    end
  end

  def down do
    alter table(:activity_log) do
      remove :remote_ip
    end
  end
end
