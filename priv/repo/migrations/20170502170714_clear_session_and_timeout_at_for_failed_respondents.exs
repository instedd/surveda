defmodule Ask.Repo.Migrations.ClearSessionAndTimeoutAtForFailedRespondents do
  use Ecto.Migration

  def up do
    Ask.Repo.query!("UPDATE respondents SET session = NULL, timeout_at = NULL WHERE state = 'failed'")
  end

  def down do
  end
end
