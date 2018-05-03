defmodule Ask.Repo.Migrations.ModifySurveyLogEntryActionDataToLongText do
  use Ecto.Migration

  def up do
    alter table(:survey_log_entries) do
      modify :action_data, :longtext
    end
  end
end
