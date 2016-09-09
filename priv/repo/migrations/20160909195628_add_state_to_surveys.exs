defmodule Ask.Repo.Migrations.AddStateToSurveys do
  use Ecto.Migration

  def change do
    alter table(:surveys) do
      add :state, :string
    end
  end
end
