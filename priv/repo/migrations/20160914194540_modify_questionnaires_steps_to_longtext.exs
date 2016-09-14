defmodule Ask.Repo.Migrations.ModifyQuestionnairesStepsToLongtext do
  use Ecto.Migration

  def up do
    alter table(:questionnaires) do
      modify :steps, :longtext
    end
  end

  def down do
    alter table(:questionnaires) do
      modify :steps, :text
    end
  end
end
