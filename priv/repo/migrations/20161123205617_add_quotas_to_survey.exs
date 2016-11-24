defmodule Ask.Repo.Migrations.AddQuotasToSurvey do
  use Ecto.Migration

  def change do
    alter table(:surveys) do
      add :quota_vars, :text
    end
  end
end
