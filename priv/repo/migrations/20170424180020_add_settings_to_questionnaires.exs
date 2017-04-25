defmodule Ask.Repo.Migrations.AddSettingsToQuestionnaires do
  use Ecto.Migration

  def change do
    alter table(:questionnaires) do
      add :settings, :text
    end
  end
end
