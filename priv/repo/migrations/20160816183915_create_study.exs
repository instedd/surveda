defmodule Ask.Repo.Migrations.CreateStudy do
  use Ecto.Migration

  def change do
    create table(:studies) do
      add :name, :string
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end
    create index(:studies, [:user_id])

  end
end
