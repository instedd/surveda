defmodule Ask.Repo.Migrations.AddMobilewebRetryConfigurationToSurveys do
  use Ecto.Migration

  def change do
    alter table(:surveys) do
      add :mobileweb_retry_configuration, :text
    end
  end
end
