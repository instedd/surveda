defmodule :"Elixir.Ask.Repo.Migrations.Add-retry-stat-id-to-respondent" do
  use Ecto.Migration

  def up do
    execute "TRUNCATE TABLE retry_stats"

    alter table(:respondents) do
      remove :retry_stat_time
      add :retry_stat_id, references(:retry_stats, on_delete: :delete_all)
    end

    alter table(:retry_stats) do
      modify(:retry_time, :string, null: false)
    end
  end

  def down do
    execute "ALTER TABLE respondents DROP FOREIGN KEY respondents_retry_stat_id_fkey"

    alter table(:respondents) do
      remove :retry_stat_id
      add :retry_stat_time, :string
    end

    alter table(:retry_stats) do
      modify(:retry_time, :string, null: true)
    end
  end
end
