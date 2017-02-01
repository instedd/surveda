defmodule Ask.Repo.Migrations.RemoveSurveyChannels do
  use Ecto.Migration

  def up do
    drop table(:survey_channels)
  end

  def down do
    create table(:survey_channels) do
      add :survey_id, references(:surveys, on_delete: :nothing)
      add :channel_id, references(:channels, on_delete: :nothing)

      timestamps()
    end
  end
end
