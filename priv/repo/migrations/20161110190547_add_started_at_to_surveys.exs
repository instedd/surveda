defmodule Ask.Repo.Migrations.AddLaunchedAtToSurveys do
  use Ecto.Migration

  def change do
    alter table(:surveys) do
      add :started_at, :datetime
    end
  end
end
