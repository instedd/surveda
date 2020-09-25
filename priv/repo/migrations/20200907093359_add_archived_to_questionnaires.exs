defmodule Ask.Repo.Migrations.AddArchivedToQuestionnaires do
  use Ecto.Migration

  def change do
    alter table(:questionnaires) do
      add :archived, :boolean, default: false
    end
  end
end
