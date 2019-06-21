defmodule Ask.Repo.Migrations.FillSurveyIdAndRespondentHashedNumbnerinRespondentDispositionHistory do
  use Ecto.Migration

  def up do
    execute "UPDATE respondent_disposition_history INNER JOIN respondents ON respondent_id = respondents.id SET respondent_disposition_history.survey_id = respondents.survey_id, respondent_disposition_history.respondent_hashed_number = respondents.hashed_number"
  end

  def down do
    execute "UPDATE respondent_disposition_history SET survey_id = NULL, respondent_hashed_number = NULL"
  end
end
