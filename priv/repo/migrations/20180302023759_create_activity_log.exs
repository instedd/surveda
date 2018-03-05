defmodule Ask.Repo.Migrations.CreateActivityLog do
  use Ecto.Migration

  def change do
    create table(:activity_log) do
      add :project_id, references(:projects, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)
      add :entity_type, :string
      add :entity_id, :integer
      add :action, :string
      add :metadata, :text

      timestamps()
    end
  end
end
