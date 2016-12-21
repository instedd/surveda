defmodule Ask.SurveyQuestionnaireTest do
  use Ask.ModelCase

  alias Ask.SurveyQuestionnaire

  @invalid_attrs %{}

  test "valid changeset foreign_key_constraints" do
    changeset = SurveyQuestionnaire.changeset(%SurveyQuestionnaire{}, %{survey_id: 1, questionnaire_id: 1})
    assert changeset.valid?
  end

  test "invalid changeset foreign_key_constraints" do
    changeset = SurveyQuestionnaire.changeset(%SurveyQuestionnaire{}, @invalid_attrs)
    refute changeset.valid?
  end
end
