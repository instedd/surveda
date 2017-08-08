defmodule Ask.Repo.Migrations.AddCompletedAtToRespondents do
  use Ecto.Migration

  def change do
    alter table(:respondents) do
      add :completed_at, :datetime
    end
  end
end
