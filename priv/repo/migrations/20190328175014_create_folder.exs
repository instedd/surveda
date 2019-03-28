defmodule Ask.Repo.Migrations.CreateFolder do
  use Ecto.Migration

  def change do
    create table(:folders) do
      add :name, :string

      timestamps()
    end
  end
end
