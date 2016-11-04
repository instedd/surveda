defmodule Ask.Repo.Migrations.AddTimezoneToSurveys do
  use Ecto.Migration

  def change do
    alter table(:surveys) do
      add :timezone, :text
    end
  end
end
