defmodule Ask.SurveyQuestionnaire do
  use AskWeb, :model

  schema "survey_questionnaires" do
    belongs_to :survey, Ask.Survey
    belongs_to :questionnaire, Ask.Questionnaire

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:survey_id, :questionnaire_id])
    |> validate_required([:survey_id, :questionnaire_id])
    |> foreign_key_constraint(:survey)
    |> foreign_key_constraint(:questionnaire)
  end
end
