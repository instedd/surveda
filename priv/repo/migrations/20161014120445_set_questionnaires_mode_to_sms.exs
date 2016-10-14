defmodule Ask.Repo.Migrations.SetQuestionnairesModeToSms do
  use Ecto.Migration

  def change do
    Ask.Repo.query "update questionnaires set mode = 'SMS'"
  end
end
