defmodule Ask.Repo.Migrations.PauseChannel do
  use Ecto.Migration

  def change do
    alter table(:channels) do
      add :paused, :boolean, default: false
    end
  end
end
