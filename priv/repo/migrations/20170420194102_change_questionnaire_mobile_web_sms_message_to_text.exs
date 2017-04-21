defmodule Ask.Repo.Migrations.ChangeQuestionnaireMobileWebSmsMessageToText do
  use Ecto.Migration

  def up do
    alter table(:questionnaires) do
      modify :mobile_web_sms_message, :text
    end
  end

  def down do
    alter table(:questionnaires) do
      modify :mobile_web_sms_message, :string
    end
  end
end
