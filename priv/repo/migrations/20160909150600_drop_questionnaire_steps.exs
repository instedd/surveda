defmodule Ask.Repo.Migrations.DropQuestionnaireSteps do
  use Ecto.Migration

  def up do
    drop table(:questionnaire_steps)
  end

  def down do
    create table(:questionnaire_steps) do
      add :type, :string
      add :settings, :map
      add :questionnaire_id, references(:questionnaires, on_delete: :nothing)

      timestamps()
    end
    create index(:questionnaire_steps, [:questionnaire_id])
  end
end
