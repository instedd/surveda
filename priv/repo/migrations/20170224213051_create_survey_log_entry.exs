defmodule Ask.Repo.Migrations.CreateSurveyLogEntry do
  use Ecto.Migration

  def change do
    create table(:survey_log_entries) do
      add :survey_id, :integer
      add :mode, :string
      add :respondent, :string
      add :channel_id, :integer
      add :disposition, :string
      add :action_type, :string
      add :action_data, :string
      add :timestamp, :datetime

      timestamps()
    end

  end
end
