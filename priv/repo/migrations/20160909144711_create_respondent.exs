defmodule Ask.Repo.Migrations.CreateRespondent do
  use Ecto.Migration

  def change do
    create table(:respondents) do
      add :phone_number, :string
      add :survey_id, references(:surveys, on_delete: :nothing)

      timestamps()
    end

    create index(:respondents, [:survey_id])
  end
end
