defmodule Ask.Repo.Migrations.FixDefaultForRetryStatTimeInRespondents do
  use Ecto.Migration

  def up do
    execute "UPDATE respondents SET retry_stat_time = 'N/A' WHERE CHAR_LENGTH(retry_stat_time) > 10"
  end

  def down do
    execute "UPDATE respondents SET retry_stat_time = NULL WHERE retry_stat_time = 'N/A'"
  end
end
