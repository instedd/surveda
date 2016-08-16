defmodule Ask.StudyTest do
  use Ask.ModelCase

  alias Ask.Study

  @valid_attrs %{name: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Study.changeset(%Study{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Study.changeset(%Study{}, @invalid_attrs)
    refute changeset.valid?
  end
end
