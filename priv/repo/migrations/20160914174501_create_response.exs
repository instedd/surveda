defmodule Ask.Repo.Migrations.CreateResponse do
  use Ecto.Migration

  def change do
    create table(:responses) do
      add :field_name, :string
      add :value, :string
      add :respondent_id, references(:respondents, on_delete: :nothing)

      timestamps()
    end
    create index(:responses, [:respondent_id])

  end
end
