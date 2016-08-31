defmodule Ask.Repo.Migrations.CreateSurvey do
  use Ecto.Migration

  def change do
    create table(:surveys) do
      add :name, :string
      add :project_id, references(:projects, on_delete: :nothing)

      timestamps()
    end
    create index(:surveys, [:project_id])

  end
end
