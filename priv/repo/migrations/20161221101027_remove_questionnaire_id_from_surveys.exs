defmodule Ask.Repo.Migrations.RemoveQuestionnaireIdFromSurveys do
  use Ecto.Migration

  def change do
    Ask.Repo.query!("update surveys set questionnaire_id = null")
    Ask.Repo.query!("alter table surveys drop foreign key surveys_questionnaire_id_fkey")
    alter table(:surveys) do
      remove :questionnaire_id
    end
  end
end
