defmodule Ask.Repo.Migrations.AddProjectToFolders do
  use Ecto.Migration

  def change do
    alter table(:folders) do
      add :project_id, references(:projects)
    end

    create index(:folders, [:project_id])
  end
end
