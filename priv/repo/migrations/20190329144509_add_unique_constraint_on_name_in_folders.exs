defmodule Ask.Repo.Migrations.AddUniqueConstraintOnNameInFolders do
  use Ecto.Migration

  def change do
    create unique_index(:folders, [:name, :project_id])
  end
end
