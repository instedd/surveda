defmodule Ask.QuestionnaireStepTest do
  use Ask.ModelCase

  alias Ask.QuestionnaireStep

  @valid_attrs %{settings: %{}, type: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = QuestionnaireStep.changeset(%QuestionnaireStep{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = QuestionnaireStep.changeset(%QuestionnaireStep{}, @invalid_attrs)
    refute changeset.valid?
  end
end
