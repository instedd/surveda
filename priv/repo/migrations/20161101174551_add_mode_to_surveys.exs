defmodule Ask.Repo.Migrations.AddModeToSurveys do
  use Ecto.Migration

  def change do
    alter table(:surveys) do
      add :mode, :text
    end
  end
end
