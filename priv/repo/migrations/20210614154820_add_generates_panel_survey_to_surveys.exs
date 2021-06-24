defmodule Ask.Repo.Migrations.AddGeneratesPanelSurveyToSurveys do
  use Ecto.Migration

  def change do
    alter table(:surveys) do
      add :generates_panel_survey, :boolean, default: false
    end
  end
end
