defmodule Ask.Repo.Migrations.SetDefaultEndedAtForAlreadyFinishedSurveys do
  use Ecto.Migration

  def up do
    Ask.Repo.query("UPDATE surveys SET ended_at = updated_at WHERE state = 'terminated'")
  end

  def down do
    # Do nothing since it doesn't make sense
  end
end
