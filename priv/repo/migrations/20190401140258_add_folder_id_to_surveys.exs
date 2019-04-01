defmodule Ask.Repo.Migrations.AddFolderIdToSurveys do
  use Ecto.Migration

  def change do
    alter table(:surveys) do
      add :folder_id, references(:folders)
    end

    create index(:surveys, [:folder_id])
  end
end
