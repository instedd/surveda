defmodule Ask.Repo.Migrations.MarkExistingSurveysAsValid do
  use Ecto.Migration

  def change do
    Ask.Repo.query!("update questionnaires set valid = ?", [true])
  end
end
