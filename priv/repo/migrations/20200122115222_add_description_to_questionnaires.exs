defmodule Ask.Repo.Migrations.AddDescriptionToQuestionnaires do
  use Ecto.Migration

  def up do
    alter table(:questionnaires) do
      add :description, :text
    end
  end

  def down do
    alter table(:questionnaires) do
      remove :description
    end
  end
end
