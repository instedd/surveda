defmodule Ask.Repo.Migrations.AddFallbackDelayToSurvey do
  use Ecto.Migration

  def change do
    alter table(:surveys) do
      add :fallback_delay, :string
    end
  end
end
