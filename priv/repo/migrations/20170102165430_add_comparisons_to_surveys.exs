defmodule Ask.Repo.Migrations.AddComparisonsToSurveys do
  use Ecto.Migration

  def change do
    alter table(:surveys) do
      add :comparisons, :text
    end
  end
end
