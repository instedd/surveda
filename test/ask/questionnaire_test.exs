defmodule Ask.QuestionnaireTest do
  use Ask.{DataCase, DummySteps}
  alias Ask.Questionnaire

  @valid_attrs %{
    project_id: 1,
    name: "some content",
    modes: ["sms", "ivr"],
    steps: [],
    settings: %{}
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Questionnaire.changeset(%Questionnaire{}, @valid_attrs)
    assert changeset.valid?
  end

  test "strips empty strings from mode list" do
    project = insert(:project)
    attrs = %{project_id: project.id, name: "some content", modes: [], steps: [], settings: %{}}
    changeset = Questionnaire.changeset(%Questionnaire{}, attrs)
    model = changeset |> Repo.insert!()
    id = model.id
    model = Repo.one(from m in Questionnaire, where: m.id == ^id)
    assert model.modes == []
  end

  test "changeset with invalid attributes" do
    changeset = Questionnaire.changeset(%Questionnaire{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "gets variables" do
    questionnaire = insert(:questionnaire, steps: @dummy_steps)
    vars = Questionnaire.variables(questionnaire)
    assert vars == ["Smokes", "Exercises", "Perfect Number", "Question"]
  end

  test "defaults to archived false" do
    assert %Questionnaire{}.archived == false
  end
end
