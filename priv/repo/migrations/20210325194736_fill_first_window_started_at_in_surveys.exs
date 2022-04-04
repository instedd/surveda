defmodule Ask.Repo.Migrations.FillFirstWindowStartedAtInSurveys do
  use Ecto.Migration

  def up do
    Ask.Repo.query(
      "UPDATE surveys SET first_window_started_at = started_at WHERE started_at IS NOT NULL"
    )
  end

  def down do
    Ask.Repo.query(
      "UPDATE surveys SET first_window_started_at = null WHERE first_window_started_at IS NOT NULL"
    )
  end
end
