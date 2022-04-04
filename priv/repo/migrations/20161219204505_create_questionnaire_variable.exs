defmodule Ask.Repo.Migrations.CreateQuestionnaireVariable do
  use Ecto.Migration

  def change do
    create table(:questionnaire_variables) do
      add :name, :string
      add :project_id, references(:projects, on_delete: :nothing)
      add :questionnaire_id, references(:questionnaires, on_delete: :nothing)

      timestamps()
    end

    create index(:questionnaire_variables, [:project_id])
    create index(:questionnaire_variables, [:questionnaire_id])
  end
end
