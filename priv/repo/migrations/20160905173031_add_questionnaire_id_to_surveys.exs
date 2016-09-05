defmodule Ask.Repo.Migrations.AddQuestionnaireIdToSurveys do
  use Ecto.Migration

  def change do
  	alter table(:surveys) do
      add :questionnaire_id, references(:questionnaires, on_delete: :nothing)
    end
  end
end
