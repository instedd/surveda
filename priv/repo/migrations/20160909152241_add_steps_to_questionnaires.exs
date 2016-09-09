defmodule Ask.Repo.Migrations.AddStepsToQuestionnaires do
  use Ecto.Migration

  def change do
    alter table(:questionnaires) do
      add :steps, :text
    end
  end
end
