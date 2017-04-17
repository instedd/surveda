defmodule Ask.Repo.Migrations.AddMobileWebSurveyIsOverMessageToQuestionnaire do
  use Ecto.Migration

  def change do
    alter table(:questionnaires) do
      add :mobile_web_survey_is_over_message, :string
    end
  end
end
