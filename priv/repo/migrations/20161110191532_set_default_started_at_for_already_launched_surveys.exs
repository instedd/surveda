defmodule Ask.Repo.Migrations.SetDefaultStartedAtForAlreadyLaunchedSurveys do
  use Ecto.Migration

  def change do
    Ask.Repo.query(
      "UPDATE surveys SET started_at = inserted_at WHERE state = 'completed' OR state = 'running'"
    )
  end
end
