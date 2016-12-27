defmodule Ask.Repo.Migrations.IndexRespondentsBySurveyIdAndState do
  use Ecto.Migration

  def change do
    create index(:respondents, [:survey_id, :state])
  end
end
