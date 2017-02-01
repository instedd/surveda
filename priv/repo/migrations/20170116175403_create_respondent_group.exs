defmodule Ask.Repo.Migrations.CreateRespondentGroup do
  use Ecto.Migration

  def change do
    create table(:respondent_groups) do
      add :name, :string
      add :survey_id, references(:surveys, on_delete: :nothing)

      timestamps()
    end

  end
end
