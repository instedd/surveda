defmodule Ask.Repo.Migrations.CreateRespondentDispositionHistory do
  use Ecto.Migration

  def change do
    create table(:respondent_disposition_history) do
      add :disposition, :string
      add :respondent_id, references(:respondents, on_delete: :nothing)

      timestamps()
    end
    create index(:respondent_disposition_history, [:respondent_id])

  end
end
