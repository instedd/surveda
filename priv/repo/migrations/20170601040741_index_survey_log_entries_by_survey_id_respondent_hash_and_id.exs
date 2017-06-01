defmodule Ask.Repo.Migrations.IndexSurveyLogEntriesBySurveyIdRespondentHashAndId do
  use Ecto.Migration

  def change do
    create index(:survey_log_entries, [:survey_id, :respondent_hashed_number, :id])
  end
end
