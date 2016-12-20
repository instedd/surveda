defmodule Ask.SurveyTest do
  use Ask.ModelCase

  alias Ask.Survey
  alias Ask.Channel

  @valid_attrs %{name: "some content", schedule_start_time: Ecto.Time.cast!("09:00:00"), schedule_end_time: Ecto.Time.cast!("18:00:00"), timezone: "UTC"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Survey.changeset(%Survey{project_id: 0}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Survey.changeset(%Survey{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "default retries configuration" do
    survey = %Survey{}
    assert [] = Survey.retries_configuration(survey, "sms")
  end

  test "parse retries configuration" do
    survey = %Survey{sms_retry_configuration: "5m 2h 3d"}
    assert [5, 120, 4320] = Survey.retries_configuration(survey, "sms")
  end

  test "handle invalid retries configuration" do
    survey = %Survey{sms_retry_configuration: "5m foo . 2 1h"}
    assert [5, 60] = Survey.retries_configuration(survey, "sms")
  end

  test "primary SMS and no fallback channel" do
    survey = %Survey{mode: [["sms"]], channels: [%Channel{type: "ivr", name: "An IVR Channel"}, %Channel{type: "sms", name: "An SMS Channel"}]}

    prim = Survey.primary_channel(survey)
    assert prim.name == "An SMS Channel"
    assert prim.type == "sms"

    fallback = Survey.fallback_channel(survey)
    assert fallback == nil
  end

   test "primary IVR and no fallback channel" do
    survey = %Survey{mode: [["ivr"]], channels: [%Channel{type: "ivr", name: "An IVR Channel"}, %Channel{type: "sms", name: "An SMS Channel"}]}

    prim = Survey.primary_channel(survey)
    assert prim.name == "An IVR Channel"
    assert prim.type == "ivr"

    fallback = Survey.fallback_channel(survey)
    assert fallback == nil
  end

  test "primary SMS and fallback IVR channel" do
    survey = %Survey{mode: [["sms", "ivr"]], channels: [%Channel{type: "ivr", name: "An IVR Channel"}, %Channel{type: "sms", name: "An SMS Channel"}]}

    prim = Survey.primary_channel(survey)
    assert prim.name == "An SMS Channel"
    assert prim.type == "sms"

    fallback = Survey.fallback_channel(survey)
    assert fallback.name == "An IVR Channel"
    assert fallback.type == "ivr"
  end

  test "primary IVR and fallback SMS channel" do
    survey = %Survey{mode: [["ivr", "sms"]], channels: [%Channel{type: "ivr", name: "An IVR Channel"}, %Channel{type: "sms", name: "An SMS Channel"}]}

    prim = Survey.primary_channel(survey)
    assert prim.name == "An IVR Channel"
    assert prim.type == "ivr"

    fallback = Survey.fallback_channel(survey)
    assert fallback.name == "An SMS Channel"
    assert fallback.type == "sms"
  end
end
