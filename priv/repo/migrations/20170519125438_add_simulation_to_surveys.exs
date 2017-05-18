defmodule Ask.Repo.Migrations.AddSimulationToSurveys do
  use Ecto.Migration

  def change do
    alter table(:surveys) do
      add :simulation, :boolean, default: false
    end
  end
end
