defmodule Ask.Repo.Migrations.IndexSurveyLogEntriesBySurveyIDAndChannelID do
  use Ecto.Migration

  def change do
    create index(:survey_log_entries, [:survey_id, :channel_id])
  end
end
