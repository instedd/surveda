defmodule :"Elixir.Ask.Repo.Migrations.Modify-retry-stats-unique-index" do
  use Ecto.Migration

  def change do
    drop unique_index(:retry_stats, [:mode, :attempt, :retry_time, :survey_id])
    create unique_index(:retry_stats, [:mode, :attempt, :retry_time, :ivr_active, :survey_id])
  end
end
