defmodule Ask.QuestionnaireTest do
  use Ask.ModelCase

  alias Ask.Questionnaire

  @valid_attrs %{project_id: 1, name: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Questionnaire.changeset(%Questionnaire{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Questionnaire.changeset(%Questionnaire{}, @invalid_attrs)
    refute changeset.valid?
  end
end
