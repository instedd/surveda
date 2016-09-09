defmodule Ask.Repo.Migrations.CreateSurveyChannel do
  use Ecto.Migration

  def change do
    create table(:survey_channels) do
      add :survey_id, references(:surveys, on_delete: :nothing)
      add :channel_id, references(:channels, on_delete: :nothing)

      timestamps()
    end

  end
end
