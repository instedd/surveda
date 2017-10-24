defmodule Ask.Repo.Migrations.AddCompletedRespondentsTable do
  use Ecto.Migration

  def change do
    create table(:completed_respondents, primary_key: false) do
      add :survey_id, references(:surveys, on_delete: :delete_all), primary_key: true
      add :questionnaire_id, :integer, primary_key: true
      add :quota_bucket_id, :integer, primary_key: true
      add :mode, :string, primary_key: true
      add :date, :date, primary_key: true
      add :count, :integer, default: 0
    end
  end
end
