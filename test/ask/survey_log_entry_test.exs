defmodule Ask.SurveyLogEntryTest do
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

  test "changeset normalizes sms mode" do
    changes = %{@valid_attrs | mode: "sms"}
    changeset = SurveyLogEntry.changeset(%SurveyLogEntry{}, changes)
    assert changeset.changes.mode == "SMS"
  end

  test "changeset normalizes ivr mode" do
    changes = %{@valid_attrs | mode: "Ivr"}
    changeset = SurveyLogEntry.changeset(%SurveyLogEntry{}, changes)
    assert changeset.changes.mode == "IVR"
  end

  test "changeset normalizes mobileweb mode" do
    changes = %{@valid_attrs | mode: "mobileWEB"}
    changeset = SurveyLogEntry.changeset(%SurveyLogEntry{}, changes)
    assert changeset.changes.mode == "Mobile Web"
  end

  test "changeset leaves unrecognized mode as it is" do
    changeset = SurveyLogEntry.changeset(%SurveyLogEntry{}, @valid_attrs)
    assert changeset.changes.mode == "some content"
  end
end
