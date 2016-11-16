defmodule Ask.RespondentTest do
  use Ask.ModelCase

  alias Ask.Respondent

  @valid_attrs %{phone_number: "+ (123) 456 789"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Respondent.changeset(%Respondent{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Respondent.changeset(%Respondent{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "sanitize phone number" do
    num = Respondent.sanitize_phone_number("+ (549) 11 1234 5627")
    assert num == "+5491112345627"
  end
end
