defmodule Ask.Repo.Migrations.IndexRespondentDispositionHistoryBySurveyIdAndId do
  use Ecto.Migration

  def change do
    create index(:respondent_disposition_history, [:survey_id, :id])
  end
end
