defmodule Ask.Repo.Migrations.CreateShortLinks do
  use Ecto.Migration

  def change do
    create table(:short_links) do
      add :hash, :string
      add :name, :string
      add :target, :string

      timestamps()
    end
  end
end
