defmodule Ask.SurveyLogEntryTest do
  use Ask.ModelCase

  alias Ask.SurveyLogEntry

  @valid_attrs %{action_data: "some content", action_type: "some content", channel_id: 42, disposition: "some content", mode: "some content", respondent_id: 42, respondent_hashed_number: "some content", survey_id: 42, timestamp: %{day: 17, hour: 14, min: 0, month: 4, sec: 0, year: 2010}}

  test "changeset with valid attributes" do
    changeset = SurveyLogEntry.changeset(%SurveyLogEntry{}, @valid_attrs)
    assert changeset.valid?
  end
end
