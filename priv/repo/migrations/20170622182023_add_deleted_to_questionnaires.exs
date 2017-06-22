defmodule Ask.Repo.Migrations.AddDeletedToQuestionnaires do
  use Ecto.Migration

  def change do
    alter table(:questionnaires) do
      add :deleted, :boolean, default: false
    end
  end
end
