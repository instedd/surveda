defmodule Ask.Repo.Migrations.RemoveInvalidRetryStatTimeInRespondents do
  use Ecto.Migration

  def up do
    execute "UPDATE respondents SET retry_stat_time = null WHERE CHAR_LENGTH(retry_stat_time) > 10"
  end
end
