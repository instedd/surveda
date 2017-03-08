defmodule Ask.Repo.Migrations.AddMobileWebSmsMessageToQuestionnaire do
  use Ecto.Migration

  def change do
    alter table(:questionnaires) do
      add :mobile_web_sms_message, :string
    end
  end
end
