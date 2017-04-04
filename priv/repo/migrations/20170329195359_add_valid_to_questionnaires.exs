defmodule Ask.Repo.Migrations.AddValidToQuestionnaires do
  use Ecto.Migration

  def change do
    alter table(:questionnaires) do
      add :valid, :boolean
    end
  end
end
