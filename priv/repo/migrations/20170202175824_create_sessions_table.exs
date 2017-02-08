defmodule Ask.Repo.Migrations.CreateSessionsTable do
  use Ecto.Migration

  def change do
    create table(:sessions) do
      add :token, :string, unique: true
      add :user_type, :string
      add :user_id, :string

      timestamps
    end

    create unique_index(:sessions, [:token])
    create index(:sessions, [:user_id])
  end
end
