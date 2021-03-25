defmodule Ask.Repo.Migrations.AddFirstWindowStartedAtToSurveys do
  use Ecto.Migration

  def change do
    alter table(:surveys) do
      add :first_window_started_at, :naive_datetime
    end
  end
end
