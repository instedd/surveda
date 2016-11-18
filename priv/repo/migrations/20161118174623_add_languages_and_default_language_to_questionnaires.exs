defmodule Ask.Repo.Migrations.AddLanguagesAndDefaultLanguageToQuestionnaires do
  use Ecto.Migration

  def change do
    alter table(:questionnaires) do
      add :languages, :text
      add :default_language, :string
    end
  end
end
