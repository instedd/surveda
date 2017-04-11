defmodule Ask.SurveyTest do
  use Ask.ModelCase

  alias Ask.Survey

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

  test "parse fallback delay" do
    survey = %Survey{fallback_delay: "2h"}
    assert Survey.fallback_delay(survey) == 120
  end

  test "returns nil fallback delay on parse failure" do
    survey = %Survey{fallback_delay: "foo"}
    assert Survey.fallback_delay(survey) == nil
  end

  describe "next_available_date_time" do
    @survey %Survey{
      schedule_start_time: Ecto.Time.cast!("09:00:00"),
      schedule_end_time: Ecto.Time.cast!("18:00:00"),
      schedule_day_of_week: %Ask.DayOfWeek{sun: true, wed: true},
      timezone: "America/Argentina/Buenos_Aires",
    }

    test "gets next available time: free slot" do
      # OK because 20hs UTC is 17hs GMT-03
      base = Ecto.DateTime.cast!("2017-03-05 20:00:00")
      time = @survey |> Survey.next_available_date_time(base)
      assert time == base
    end

    test "gets next available time: this day, earlier" do
      # 9hs UTC is 6hs GMT-03
      base = Ecto.DateTime.cast!("2017-03-05 09:00:00")
      time = @survey |> Survey.next_available_date_time(base)
      # 12hs UTC is 9hs GMT-03
      assert time == Ecto.DateTime.cast!("2017-03-05 12:00:00")
    end

    test "gets next available time: this day, too late" do
      # 9hs UTC is 6hs GMT-03
      base = Ecto.DateTime.cast!("2017-03-05 22:00:00")
      time = @survey |> Survey.next_available_date_time(base)
      # Next available day is Wednesday
      assert time == Ecto.DateTime.cast!("2017-03-08 12:00:00")
    end

    test "gets next available time: unavaible day" do
      base = Ecto.DateTime.cast!("2017-03-06 15:00:00")
      time = @survey |> Survey.next_available_date_time(base)
      assert time == Ecto.DateTime.cast!("2017-03-08 12:00:00")
    end
  end
end
