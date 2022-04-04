defmodule Ask.Repo.Migrations.MigrateSurveyQuestionnaireIdToSurveyQuestionnaires do
  use Ecto.Migration

  alias Ask.Repo

  defmodule Questionnaire do
    use Ask.Web, :model

    schema "questionnaires" do
    end
  end

  defmodule Survey do
    use Ask.Web, :model

    schema "surveys" do
      belongs_to :questionnaire, Questionnaire
    end
  end

  defmodule SurveyQuestionnaire do
    use Ask.Web, :model

    schema "survey_questionnaires" do
      belongs_to :survey, Survey
      belongs_to :questionnaire, Questionnaire

      Ecto.Schema.timestamps()
    end
  end

  def change do
    Survey
    |> Repo.all()
    |> Enum.each(fn survey ->
      if survey.questionnaire_id do
        %SurveyQuestionnaire{
          survey_id: survey.id,
          questionnaire_id: survey.questionnaire_id
        }
        |> Repo.insert()
      end
    end)
  end
end
