defmodule Ask.Repo.Migrations.AddArchivedToProjects do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      add :archived, :boolean, default: false
    end
  end
end
