defmodule Ask.Repo.Migrations.AddCountPartialResultsToSurveys do
  use Ecto.Migration

  def change do
    alter table(:surveys) do
      add :count_partial_results, :boolean, default: false
    end
  end
end
