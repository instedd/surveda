defmodule AskWeb.QuestionnaireVariableTest do
  use Ask.DataCase

  alias Ask.QuestionnaireVariable

  @valid_attrs %{name: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = QuestionnaireVariable.changeset(%QuestionnaireVariable{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = QuestionnaireVariable.changeset(%QuestionnaireVariable{}, @invalid_attrs)
    refute changeset.valid?
  end
end
