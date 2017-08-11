defmodule Ask.Repo.Migrations.AddCompletedAtToRespondents do
  use Ecto.Migration

  def change do
    alter table(:respondents) do
      add :completed_at, :utc_datetime
    end
  end
end
