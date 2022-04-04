defmodule Ask.Repo.Migrations.AddSaltToProjects do
  use Ecto.Migration

  def up do
    alter table(:projects) do
      add :salt, :string
    end
  end

  def down do
    alter table(:projects) do
      remove :salt
    end
  end
end
