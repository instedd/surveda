defmodule Ask.Repo.Migrations.PrefixRespondentHashNumber do
  use Ecto.Migration

  def up do
    execute "UPDATE respondents SET hashed_number = CONCAT('r', hashed_number)"

    execute "UPDATE respondent_disposition_history SET respondent_hashed_number = CONCAT('r', respondent_hashed_number)"

    execute "UPDATE survey_log_entries SET respondent_hashed_number = CONCAT('r', respondent_hashed_number)"
  end

  def down do
    execute "UPDATE survey_log_entries SET respondent_hashed_number = TRIM(LEADING 'r' FROM respondent_hashed_number)"

    execute "UPDATE respondent_disposition_history SET respondent_hashed_number = TRIM(LEADING 'r' FROM respondent_hashed_number)"

    execute "UPDATE respondents SET hashed_number = TRIM(LEADING 'r' FROM hashed_number)"
  end
end
