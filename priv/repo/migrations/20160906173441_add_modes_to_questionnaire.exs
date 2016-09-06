defmodule Ask.Repo.Migrations.AddModesToQuestionnaire do
  use Ecto.Migration

  def change do
    alter table(:questionnaires) do
      add :modes, :string
    end
  end
end
