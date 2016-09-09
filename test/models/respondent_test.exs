defmodule Ask.RespondentTest do
  use Ask.ModelCase

  alias Ask.Respondent

  @valid_attrs %{phone_number: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Respondent.changeset(%Respondent{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Respondent.changeset(%Respondent{}, @invalid_attrs)
    refute changeset.valid?
  end
end
