defmodule Ask.Repo.Migrations.CreateProjectMembership do
  use Ecto.Migration

  def change do
    create table(:project_memberships) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :project_id, references(:projects, on_delete: :delete_all)
      add :level, :string

      timestamps()
    end
  end
end
