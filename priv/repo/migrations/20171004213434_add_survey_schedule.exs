defmodule Ask.Repo.Migrations.AddSurveySchedule do
  use Ecto.Migration

  def up do
    alter table(:surveys) do
      add :schedule, :text
    end
  end

  def down do
    alter table(:surveys) do
      remove :schedule
    end
  end
end
