defmodule Ask.Repo.Migrations.AddDescriptionToSurveys do
  use Ecto.Migration

  def up do
    alter table(:surveys) do
      add :description, :text
    end
  end

  def down do
    alter table(:surveys) do
      remove :description
    end
  end
end
