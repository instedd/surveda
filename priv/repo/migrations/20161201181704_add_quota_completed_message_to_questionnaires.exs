defmodule Ask.Repo.Migrations.AddQuotaCompletedMessageToQuestionnaires do
  use Ecto.Migration

  def change do
    alter table(:questionnaires) do
      add :quota_completed_msg, :text
    end
  end
end
