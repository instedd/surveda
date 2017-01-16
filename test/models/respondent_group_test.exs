defmodule Ask.RespondentGroupTest do
  use Ask.ModelCase

  alias Ask.RespondentGroup

  @valid_attrs %{name: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = RespondentGroup.changeset(%RespondentGroup{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = RespondentGroup.changeset(%RespondentGroup{}, @invalid_attrs)
    refute changeset.valid?
  end
end
