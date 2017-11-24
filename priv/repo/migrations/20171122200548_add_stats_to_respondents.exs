defmodule Ask.Repo.Migrations.AddStatsToRespondents do
  use Ecto.Migration

  def change do
   alter table(:respondents) do
      add :stats, :longtext
    end
  end
end
