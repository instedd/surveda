defmodule Ask.RespondentGroupChannelTest do
  use Ask.DataCase

  alias Ask.RespondentGroupChannel

  @valid_attrs %{channel_id: 1, respondent_group_id: 2, mode: "a"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = RespondentGroupChannel.changeset(%RespondentGroupChannel{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = RespondentGroupChannel.changeset(%RespondentGroupChannel{}, @invalid_attrs)
    refute changeset.valid?
  end
end
