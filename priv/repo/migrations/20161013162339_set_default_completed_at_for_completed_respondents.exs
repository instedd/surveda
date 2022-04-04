defmodule Ask.Repo.Migrations.SetDefaultCompletedAtForCompletedRespondents do
  use Ecto.Migration

  def change do
    Ask.Repo.query(
      "UPDATE respondents SET completed_at = updated_at WHERE state = 'completed' AND completed_at IS NULL"
    )
  end
end
