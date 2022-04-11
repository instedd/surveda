defmodule AskWeb.SurveyLogEntryTest do
  use Ask.DataCase

  alias Ask.SurveyLogEntry

  @valid_attrs %{
    action_data: "some content",
    action_type: "some content",
    channel_id: 42,
    disposition: "some content",
    mode: "some content",
    respondent_id: 42,
    respondent_hashed_number: "some content",
    survey_id: 42,
    timestamp: "2010-04-17T14:00:00Z"
  }

  test "changeset with valid attributes" do
    changeset = SurveyLogEntry.changeset(%SurveyLogEntry{}, @valid_attrs)
    assert changeset.valid?
  end
end
