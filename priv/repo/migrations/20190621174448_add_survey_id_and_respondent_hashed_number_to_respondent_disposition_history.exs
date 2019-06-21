defmodule Ask.Repo.Migrations.AddSurveyIdAndRespondentHashedNumberToRespondentDispositionHistory do
  use Ecto.Migration

  def change do
    alter table(:respondent_disposition_history) do
      add :survey_id, references(:surveys, on_delete: :delete_all)
      add :respondent_hashed_number, :string
    end
  end
end
