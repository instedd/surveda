defmodule Ask.Repo.Migrations.AddSettingsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :settings, :text
    end
  end
end
