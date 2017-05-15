defmodule Ask.Repo.Migrations.AddQuestionnaireQuotaCompletedSteps do
  use Ecto.Migration

  def change do
    alter table(:questionnaires) do
      add :quota_completed_steps, :longtext
    end
  end
end
