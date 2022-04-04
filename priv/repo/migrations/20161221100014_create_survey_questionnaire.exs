defmodule Ask.Repo.Migrations.CreateSurveyQuestionnaire do
  use Ecto.Migration

  def change do
    create table(:survey_questionnaires) do
      add :survey_id, references(:surveys, on_delete: :nothing)
      add :questionnaire_id, references(:questionnaires, on_delete: :nothing)

      timestamps()
    end

    create index(:survey_questionnaires, [:survey_id])
    create index(:survey_questionnaires, [:questionnaire_id])
  end
end
