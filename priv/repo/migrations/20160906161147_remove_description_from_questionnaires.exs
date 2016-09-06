defmodule Ask.Repo.Migrations.RemoveDescriptionFromQuestionnaires do
  use Ecto.Migration

  def change do
    alter table(:questionnaires) do
      remove :description
    end
  end
end
