defmodule Ask.Repo.Migrations.SetDefaultArchivedToProjects do
  use Ecto.Migration

  def up do
    Ask.Repo.query!("UPDATE projects SET archived = false")
  end

  def down do
  end
end
