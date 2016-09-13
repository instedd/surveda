defmodule Ask.Repo.Migrations.AddCutoffToSurveys do
  use Ecto.Migration

  def change do
    alter table(:surveys) do
      add :cutoff, :integer
    end
  end
end
