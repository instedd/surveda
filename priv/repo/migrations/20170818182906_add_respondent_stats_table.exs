defmodule Ask.Repo.Migrations.AddRespondentStatsTable do
  use Ecto.Migration

  def change do
    create table(:respondent_stats, primary_key: false) do
      add :survey_id, references(:surveys, on_delete: :delete_all), primary_key: true
      add :questionnaire_id, :integer, primary_key: true
      add :state, :string, primary_key: true
      add :disposition, :string, primary_key: true
      add :count, :integer, default: 0
    end
  end
end
