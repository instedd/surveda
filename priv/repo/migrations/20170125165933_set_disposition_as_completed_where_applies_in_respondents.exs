defmodule Ask.Repo.Migrations.SetDispositionAsCompletedWhereAppliesInRespondents do
  use Ecto.Migration

  def up do
    Ask.Repo.query("UPDATE respondents SET disposition = 'completed' WHERE state = 'completed'")
  end

  def down do
    Ask.Repo.query("UPDATE respondents SET disposition = NULL WHERE state = 'completed'")
  end
end
