defmodule Ask.RespondentDispositionHistoryTest do
  use Ask.ModelCase

  alias Ask.RespondentDispositionHistory

  @valid_attrs %{disposition: "some content", mode: "sms"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = RespondentDispositionHistory.changeset(%RespondentDispositionHistory{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = RespondentDispositionHistory.changeset(%RespondentDispositionHistory{}, @invalid_attrs)
    refute changeset.valid?
  end
end
