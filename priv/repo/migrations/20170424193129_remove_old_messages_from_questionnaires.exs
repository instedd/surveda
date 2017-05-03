defmodule Ask.Repo.Migrations.RemoveOldMessagesFromQuestionnaires do
  use Ecto.Migration

  def up do
    alter table(:questionnaires) do
      remove :error_msg
      remove :mobile_web_sms_message
      remove :mobile_web_survey_is_over_message
      remove :quota_completed_msg
    end
  end

  def down do
    alter table(:questionnaires) do
      add :error_msg, :text
      add :mobile_web_sms_message, :text
      add :mobile_web_survey_is_over_message, :string
      add :quota_completed_msg, :string
    end
  end
end
