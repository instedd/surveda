defmodule Ask.Repo.Migrations.AddIncentivesEnabledToSurveys do
  use Ecto.Migration

  def change do
    alter table(:surveys) do
      add :incentives_enabled, :boolean, default: true
    end
  end
end
