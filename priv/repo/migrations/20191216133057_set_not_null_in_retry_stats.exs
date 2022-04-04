defmodule :"Elixir.Ask.Repo.Migrations.Set-not-null-in-retry-stats" do
  use Ecto.Migration

  def up do
    execute "DELETE FROM retry_stats WHERE mode IS NULL or attempt IS NULL or retry_time IS NULL or count IS NULL or survey_id IS NULL"
    execute "ALTER TABLE retry_stats DROP FOREIGN KEY retry_stats_survey_id_fkey"

    alter table(:retry_stats) do
      modify :mode, :string, null: false
      modify :attempt, :integer, null: false
      modify :retry_time, :string, null: false
      modify :count, :integer, null: false
      modify :survey_id, references(:surveys, on_delete: :delete_all), null: false
    end
  end

  def down do
    execute "ALTER TABLE retry_stats DROP FOREIGN KEY retry_stats_survey_id_fkey"

    alter table(:retry_stats) do
      modify :mode, :string, null: true
      modify :attempt, :integer, null: true
      modify :retry_time, :string, null: true
      modify :count, :integer, null: true
      modify :survey_id, references(:surveys, on_delete: :delete_all), null: true
    end
  end
end
