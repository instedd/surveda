defmodule Ask.Repo.Migrations.SetDefaultComparisonsOnSurveys do
  use Ecto.Migration

  def up do
    Ask.Repo.query("UPDATE surveys SET comparisons = '[]' WHERE comparisons IS NULL")
  end

  def down do
    Ask.Repo.query("UPDATE surveys SET comparisons = NULL WHERE comparisons = '[]'")
  end
end
