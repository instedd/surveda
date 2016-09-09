defmodule Ask.SurveyChannelTest do
  use Ask.ModelCase

  alias Ask.SurveyChannel

  @invalid_attrs %{}

  test "valid changeset foreign_key_constraints" do
    changeset = SurveyChannel.changeset(%SurveyChannel{}, %{survey_id: 1, channel_id: 1})
    assert changeset.valid?
  end

  test "invalid changeset foreign_key_constraints" do
    changeset = SurveyChannel.changeset(%SurveyChannel{}, @invalid_attrs)
    refute changeset.valid?
  end
end
