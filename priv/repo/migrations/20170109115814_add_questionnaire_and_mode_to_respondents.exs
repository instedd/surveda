defmodule Ask.Repo.Migrations.AddQuestionnaireAndModeToRespondents do
  use Ecto.Migration

  def change do
    alter table(:respondents) do
      add :questionnaire_id, references(:questionnaires)
      add :mode, :string
    end
  end
end
