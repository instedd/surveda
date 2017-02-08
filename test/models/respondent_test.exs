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
    assert num == "5491112345627"
  end

  test "hash phone number" do
    salt = "32f0599c-6861-48a9-bf40-753844b5920f"
    hash = Respondent.hash_phone_number("+ (549) 11 1234 5627", salt)

    assert hash == "4e57ba03c44d"
  end

  test "hash phone number should be different for different projects" do
    salt1 = "32f0599c-6861-48a9-bf40-753844b5920f"
    salt2 = "32f0599c-6862-48a9-bf40-753844b5920f"
    hash1 = Respondent.hash_phone_number("+ (549) 11 1234 5627", salt1)
    hash2 = Respondent.hash_phone_number("+ (549) 11 1234 5627", salt2)

    assert hash1 != hash2
  end
end
