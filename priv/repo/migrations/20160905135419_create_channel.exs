defmodule Ask.Repo.Migrations.CreateChannel do
  use Ecto.Migration

  def change do
    create table(:channels) do
      add :name, :string
      add :type, :string
      add :provider, :string
      add :settings, :map
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end
    create index(:channels, [:user_id])

  end
end
