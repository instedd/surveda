defmodule Ask.Repo.Migrations.CreateAudios do
  use Ecto.Migration

  def change do
    create table(:audios) do
      add :uuid, :string
      add :data, :mediumblob
      add :filename, :string
      add :source, :string
      add :duration, :integer

      timestamps()
    end

  end
end
