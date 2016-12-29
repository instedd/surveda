defmodule Ask.Repo.Migrations.IndexRespondentsByStateAndTimeout do
  use Ecto.Migration

  def change do
    create index(:respondents, [:state, :timeout_at])
  end
end
