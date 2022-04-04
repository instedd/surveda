defmodule Ask.Repo.Migrations.CreateQuestionnaire do
  use Ecto.Migration

  def change do
    create table(:questionnaires) do
      add :name, :string
      add :description, :string
      add :project_id, references(:projects, on_delete: :nothing)

      timestamps()
    end

    create index(:questionnaires, [:project_id])
  end
end
