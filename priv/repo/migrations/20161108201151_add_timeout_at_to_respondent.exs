defmodule Ask.Repo.Migrations.AddTimeoutAtToRespondent do
  use Ecto.Migration

  def change do
    alter table(:respondents) do
      add :timeout_at, :naive_datetime
    end
  end
end
