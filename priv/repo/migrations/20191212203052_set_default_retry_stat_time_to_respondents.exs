defmodule Ask.Repo.Migrations.SetDefaultRetryStatTimeToRespondents do
  use Ecto.Migration

  def up do
    execute "UPDATE respondents SET retry_stat_time = timeout_at WHERE timeout_at IS NOT NULL AND retry_stat_time IS NULL"
  end

  def down do
    execute "UPDATE respondents SET retry_stat_time = NULL"
  end
end
