defmodule Ask.Repo.Migrations.SetQuestionnairesModeToSms do
  use Ecto.Migration

  def change do
    Ask.Repo.query!("update questionnaires set modes = 'SMS'")
  end
end
