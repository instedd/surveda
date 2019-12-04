defmodule Ask.RespondentTest do
  use Ask.ModelCase
  import Ask.Factory
  alias Ask.Schedule

  alias Ask.{Respondent, Repo, Stats}

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

    assert hash == "r4e57ba03c44d"
  end

  test "phone number hash is prefixed" do
    salt = "550a8b7d-b050-476f-81c6-11e1de610116"
    hash = Respondent.hash_phone_number("+1 408-471-5758", salt)

    assert hash |> String.starts_with?("r")
  end

  test "hash phone number should be different for different projects" do
    salt1 = "32f0599c-6861-48a9-bf40-753844b5920f"
    salt2 = "32f0599c-6862-48a9-bf40-753844b5920f"
    hash1 = Respondent.hash_phone_number("+ (549) 11 1234 5627", salt1)
    hash2 = Respondent.hash_phone_number("+ (549) 11 1234 5627", salt2)

    assert hash1 != hash2
  end

  test "respondent mobile token should be always the same for the same respondent id" do
    assert Respondent.token(1) == Respondent.token(1)

    assert Respondent.token(1) != Respondent.token(2)
  end

  test "respondent stats should be empty by default" do
    respondent = build(:respondent) |> Repo.insert!
    respondent = Respondent |> Repo.get(respondent.id)

    assert respondent.stats == %Stats{}

    assert respondent.stats |> Stats.add_sent_sms |> Stats.total_sent_sms == 1
  end

  test "next raw time out equals next final timeout when the survey is active" do
    survey = insert(:survey, %{schedule: Schedule.always()})
    respondent = insert(:respondent, survey: survey)
    {:ok, now, _} = DateTime.from_iso8601("2000-01-01T00:00:00Z")
    {:ok, expected_timeout, _} = DateTime.from_iso8601("2000-01-01T02:00:00Z")
    timeout = 120

    assert Respondent.next_raw_timeout(timeout, now) == expected_timeout
    assert Respondent.next_final_timeout(respondent, timeout, now) == expected_timeout
  end

  test "next raw time out differs from next final timeout when the survey is inactive" do
    survey = insert(:survey, %{schedule: Schedule.default()})
    respondent = insert(:respondent, survey: survey)
    {:ok, now, _} = DateTime.from_iso8601("2019-10-02T00:00:00Z")
    {:ok, expected_raw_timeout, _} = DateTime.from_iso8601("2019-10-02T02:00:00Z")
    {:ok, expected_final_timeout, _} = DateTime.from_iso8601("2019-10-02T09:00:00Z")
    timeout = 120

    assert Respondent.next_raw_timeout(timeout, now) == expected_raw_timeout
    assert Respondent.next_final_timeout(respondent, timeout, now) == expected_final_timeout
  end

end
