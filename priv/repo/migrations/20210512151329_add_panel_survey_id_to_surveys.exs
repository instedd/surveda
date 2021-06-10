defmodule Ask.Repo.Migrations.AddPanelSurveyIdToSurveys do
  use Ecto.Migration

  def up do
    alter table(:surveys) do
      add(:panel_survey_id, references(:panel_surveys))
    end
  end

  def down do
    # From [Ecto](https://hexdocs.pm/ecto_sql/Ecto.Migration.html#module-change):
    # "Having to write both up/0 and down/0 functions for every migration is tedious and error prone."
    # But adding the foreign key that way doesn't allow rollbacking the current migration.
    # The following error is thrown:
    # "Cannot drop index 'surveys_panel_survey_id_fkey': needed in a foreign key constraint"
    # So the foreign key must manually droped to allow the rollback.
    execute "alter table surveys drop foreign key surveys_panel_survey_id_fkey;"

    alter table(:surveys) do
      remove :panel_survey_id
    end
  end
end
