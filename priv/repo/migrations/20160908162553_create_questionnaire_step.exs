defmodule Ask.Repo.Migrations.CreateQuestionnaireStep do
  use Ecto.Migration

  def change do
    create table(:questionnaire_steps) do
      add :type, :string
      add :settings, :map
      add :questionnaire_id, references(:questionnaires, on_delete: :nothing)

      timestamps()
    end
    create index(:questionnaire_steps, [:questionnaire_id])

  end
end
