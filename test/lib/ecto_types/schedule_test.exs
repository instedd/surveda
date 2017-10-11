defmodule Ask.ScheduleTest do
  use Ask.ModelCase
  alias Ask.{Schedule, DayOfWeek}

  @default_schedule Schedule.default()

  test "always" do
    assert %Schedule{day_of_week: %DayOfWeek{sun: true, mon: true, tue: true, wed: true, thu: true, fri: true, sat: true}, start_time: ~T[00:00:00], end_time: ~T[23:59:59], blocked_days: [], timezone: "Etc/UTC"} == Schedule.always()
  end

  test "default" do
    assert %Schedule{day_of_week: %DayOfWeek{}, start_time: ~T[09:00:00], end_time: ~T[18:00:00], blocked_days: [], timezone: "Etc/UTC"} == Schedule.default()
  end

  describe "dump:" do
    test "should dump weekdays" do
      {:ok, start_time} = Time.new(9,0,0)
      {:ok, end_time} = Time.new(18,0,0)
      assert {:ok, "{\"timezone\":\"Etc/UTC\",\"start_time\":\"09:00:00\",\"end_time\":\"18:00:00\",\"day_of_week\":[\"mon\",\"tue\",\"wed\",\"thu\",\"fri\"],\"blocked_days\":[]}"} == Schedule.dump(%Schedule{day_of_week: %DayOfWeek{mon: true, tue: true, wed: true, thu: true, fri: true}, start_time: start_time, end_time: end_time, timezone: Schedule.default_timezone()})
    end

    test "should dump default" do
      assert {:ok, "{\"timezone\":\"Etc/UTC\",\"start_time\":\"09:00:00\",\"end_time\":\"18:00:00\",\"day_of_week\":[],\"blocked_days\":[]}"} == Schedule.dump(Schedule.default())
    end

    test "should dump always" do
      assert {:ok, "{\"timezone\":\"Etc/UTC\",\"start_time\":\"00:00:00\",\"end_time\":\"23:59:59\",\"day_of_week\":[\"sun\",\"mon\",\"tue\",\"wed\",\"thu\",\"fri\",\"sat\"],\"blocked_days\":[]}"} == Schedule.dump(Schedule.always())
    end
  end

  describe "load:" do
    test "should load weekdays" do
      assert {:ok, %Schedule{day_of_week: %DayOfWeek{mon: true, tue: true, wed: true, thu: true, fri: true, sun: false, sat: false}, start_time: ~T[09:00:00], end_time: ~T[18:00:00], blocked_days: [], timezone: "America/Argentina/Buenos_Aires"}} == Schedule.load("{\"timezone\":\"America/Argentina/Buenos_Aires\",\"start_time\":\"09:00:00\",\"end_time\":\"18:00:00\",\"day_of_week\":[\"mon\",\"tue\",\"wed\",\"thu\",\"fri\"],\"blocked_days\":[]}")
    end
  end

  describe "cast:" do
    test "shuld cast to itself" do
      assert {:ok, %Schedule{day_of_week: %DayOfWeek{}, start_time: ~T[09:00:00], end_time: ~T[18:00:00], blocked_days: [], timezone: "Etc/UTC"}} == Schedule.cast(Schedule.default())
    end

    test "should cast string times" do
      assert {
        :ok,
        %Schedule{day_of_week: %DayOfWeek{sun: true, mon: true, tue: true, wed: true, thu: true, fri: false, sat: true}, start_time: ~T[09:00:00], end_time: ~T[19:00:00], blocked_days: [], timezone: "Etc/UTC"}
      } == Schedule.cast(%{day_of_week: %{sun: true, mon: true, tue: true, wed: true, thu: true, fri: false, sat: true}, start_time: "09:00:00", end_time: "19:00:00", timezone: "Etc/UTC", blocked_days: []})
    end

    test "should cast string times with string keys" do
      assert {
        :ok,
        %Schedule{day_of_week: %DayOfWeek{sun: true, mon: true, tue: true, wed: true, thu: true, fri: false, sat: true}, start_time: ~T[09:00:00], end_time: ~T[19:00:00], blocked_days: [], timezone: "Etc/UTC"}
      } == Schedule.cast(%{"day_of_week" => %{"sun" => true, "mon" => true, "tue" => true, "wed" => true, "thu" => true, "fri" => false, "sat" => true}, "start_time" => "09:00:00", "end_time" => "19:00:00", "timezone" => "Etc/UTC"})
    end

    test "shuld cast a struct with string keys" do
      assert {
        :ok,
        %Schedule{day_of_week: %DayOfWeek{sun: true, mon: true, tue: true, wed: true, thu: true, fri: false, sat: true}, start_time: ~T[09:00:00], end_time: ~T[19:00:00], blocked_days: []}
      } == Schedule.cast(%{"day_of_week" => %{"sun" => true, "mon" => true, "tue" => true, "wed" => true, "thu" => true, "fri" => false, "sat" => true}, "start_time" => ~T[09:00:00], "end_time" => ~T[19:00:00]})
    end

    test "shuld cast nil" do
      assert {:ok, @default_schedule} == Schedule.cast(nil)
    end
  end
end
