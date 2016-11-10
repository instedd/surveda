defmodule Ask.Repo.Migrations.AddRetryConfigurationToSurveys do
  use Ecto.Migration

  def change do
    alter table(:surveys) do
      add :sms_retry_configuration, :text
      add :ivr_retry_configuration, :text
    end

  end
end
