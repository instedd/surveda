defmodule Ask.Repo.Migrations.DeleteObsoletePanelSurveys do
  use Ecto.Migration

  # At the time this migration takes place, panel surveys aren't productive yet. So having changed
  # the panel survey model, it's much more easier to destroy every obsolete panel survey in the DB
  # than trying to adapt it to the new model.
  def up do
    execute "alter table surveys drop foreign key surveys_panel_survey_of_fkey;"
    execute "delete from surveys where panel_survey_of is not null;"

    alter table(:surveys) do
      # These fields are obsolete too.
      remove :panel_survey_of
      remove :latest_panel_survey
    end
  end

  def down do
    # This migration is destructive. The deleted surveys cannot be recovered.

    alter table(:surveys) do
      add :panel_survey_of, references(:surveys, on_delete: :nothing)
      add :latest_panel_survey, :boolean, default: false
    end
  end
end
