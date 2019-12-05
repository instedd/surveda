defmodule Ask.Repo.Migrations.AddEndedAtToSurveys do
  use Ecto.Migration

  def change do
    alter table(:surveys) do
      add :ended_at, :naive_datetime
    end
  end
end

