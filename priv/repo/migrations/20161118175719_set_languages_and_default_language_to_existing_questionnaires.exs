defmodule Ask.Repo.Migrations.SetLanguagesAndDefaultLanguageToExistingQuestionnaires do
  use Ecto.Migration

  def change do
    Ask.Repo.query!(~s(update questionnaires set languages = '["en"]', default_language = 'en'))
  end
end
