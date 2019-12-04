defmodule Ask.Repo.Migrations.AddSectionOrderToRespondent do
  use Ecto.Migration

  def change do
    alter table(:respondents) do
      add :retry_stat_time, :string
    end
  end
end
