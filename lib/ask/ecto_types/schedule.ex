defmodule Ask.Schedule do
  @moduledoc """
  A custom type to map schedules to the database

  This type contains an Ask.DayOfWeek, start and end time for each day, and
  a list of blocked days such as holidays
  """

  @behaviour Ecto.Type

  alias __MODULE__
  alias Ask.DayOfWeek

  defstruct [:day_of_week, :start_time, :end_time, :blocked_days, :timezone]

  def type, do: :text

  def cast(%Schedule{} = schedule) do
    {:ok, schedule}
  end
  def cast(%{start_time: start_time} = schedule) when is_binary(start_time) do
    cast(%{schedule | start_time: Time.from_iso8601!(start_time)})
  end
  def cast(%{end_time: end_time} = schedule) when is_binary(end_time) do
    cast(%{schedule | end_time: Time.from_iso8601!(end_time)})
  end
  def cast(%{day_of_week: day_of_week, start_time: start_time, end_time: end_time, blocked_days: blocked_days, timezone: timezone}) do
    case DayOfWeek.cast(day_of_week) do
      :error -> :error
      {:ok, dow} ->
        {:ok, %Schedule{day_of_week: dow, start_time: start_time, end_time: end_time, blocked_days: cast_blocked_days(blocked_days), timezone: timezone}}
    end
  end
  def cast(%{} = map) do
    cast(%{
      day_of_week: map["day_of_week"],
      start_time: map["start_time"],
      end_time: map["end_time"],
      blocked_days: map["blocked_days"],
      timezone: map["timezone"]
    })
  end
  def cast(string) when is_binary(string), do: load(string)
  def cast(nil), do: {:ok, default()}
  def cast(_), do: :error

  defp cast_blocked_days([blocked_day | blocked_days]) when is_binary(blocked_day) do
    [Date.from_iso8601!(blocked_day) | cast_blocked_days(blocked_days)]
  end
  defp cast_blocked_days([blocked_day | blocked_days]) do
    [blocked_day | cast_blocked_days(blocked_days)]
  end
  defp cast_blocked_days(_), do: []

  def load(string) when is_binary(string), do: cast(Poison.decode!(string))
  def load(nil), do: {:ok, default()}
  def load(_), do: :error

  def dump(%Schedule{day_of_week: day_of_week}=schedule) do
    {:ok, day_of_week}= DayOfWeek.dump(day_of_week)
    schedule = %{schedule |
      day_of_week: day_of_week,
      blocked_days: schedule.blocked_days || []
    }
    Poison.encode(schedule)
  end
  def dump(_), do: :error

  def validate(schedule) do
    if schedule.start_time && schedule.end_time && schedule.start_time >= schedule.end_time do
      :error
    else
      :ok
    end
  end

  def intersect?(%Schedule{day_of_week: days, start_time: start_time, end_time: end_time, timezone: timezone}, %DateTime{} = date_time) do
    date_time = date_time
    |> Timex.to_datetime(timezone)

    time = DateTime.to_time(date_time)

    DayOfWeek.intersect?(days, DayOfWeek.from(date_time))
      && start_time <= time
      && end_time >= time
  end

  def default() do
    %Schedule{
      day_of_week: DayOfWeek.never(),
      start_time: ~T[09:00:00],
      end_time: ~T[18:00:00],
      blocked_days: [],
      timezone: default_timezone()
    }
  end

  def always() do
    %Schedule{
      day_of_week: DayOfWeek.every_day(),
      start_time: ~T[00:00:00],
      end_time: ~T[23:59:59],
      blocked_days: [],
      timezone: default_timezone()
    }
  end

  def default_timezone() do
    "Etc/UTC"
  end

  def next_available_date_time(%Schedule{} = schedule, %DateTime{} = date_time) do
    # TODO: Remove the necessity of converting this to erl dates
    date_time = date_time
    |> Timex.to_datetime(schedule.timezone)

    {erl_date, erl_time} = date_time |> Timex.to_erl

    {:ok, time} = erl_time
    |> Time.from_erl

    # If this day is enabled in the schedule
    date_time = if day_of_week_available?(schedule, erl_date) do
      # Check if the time is inside the schedule time range
      case compare_time(schedule, time) do
        :before ->
          # If it's before the time range, move it to the beginning of the range
          at_start_time(schedule, erl_date)
        :inside ->
          # If it's inside there's nothing to do
          date_time
        :after ->
          # If it's after the time range, find the next day
          next_available_date_time_internal(schedule, erl_date)
      end
    else
      # If the day is not enabled, find the next day
      next_available_date_time_internal(schedule, erl_date)
    end

    date_time
    |> Timex.Timezone.convert("Etc/UTC")
  end

  defp compare_time(%Schedule{start_time: start_time, end_time: end_time}, time) do
    case Time.compare(time, start_time) do
      :lt -> :before
      :eq -> :inside
      :gt ->
        case Time.compare(time, end_time) do
          :lt -> :inside
          :eq -> :inside
          :gt -> :after
        end
    end
  end

  defp at_start_time(schedule, erl_date) do
    erl_time = schedule.start_time |> Time.to_erl
    Timex.Timezone.resolve(schedule.timezone, {erl_date, erl_time})
  end

  defp next_available_date_time_internal(schedule, erl_date) do
    erl_date = next_available_date(schedule, erl_date)
    at_start_time(schedule, erl_date)
  end

  defp next_available_date(schedule, erl_date) do
    erl_date = Timex.shift(erl_date, days: 1)
    if day_of_week_available?(schedule, erl_date) do
      erl_date
    else
      next_available_date(schedule, erl_date)
    end
  end

  defp day_of_week_available?(%Schedule{day_of_week: day_of_week, blocked_days: blocked_days}, erl_date) do
    if day_of_week == DayOfWeek.never do
      # Just in case a schedule remains empty (can happen in a test)
      true
    else
      case :calendar.day_of_the_week(erl_date) do
        1 -> day_of_week.mon
        2 -> day_of_week.tue
        3 -> day_of_week.wed
        4 -> day_of_week.thu
        5 -> day_of_week.fri
        6 -> day_of_week.sat
        7 -> day_of_week.sun
      end && !Enum.member?(blocked_days, erl_date |> Date.from_erl!)
    end
  end

  def any_day_selected?(%Schedule{day_of_week: day_of_week}) do
    DayOfWeek.any_day_selected?(day_of_week)
  end

  def adjust_date_to_timezone(%Schedule{} = schedule, date) do
    date
    |> Timex.Timezone.convert(schedule.timezone)
  end

  def timezone_offset(%Schedule{} = schedule) do
    offset = schedule.timezone
    |> Timex.Timezone.get
    |> Timex.Timezone.total_offset

    hours = round(offset / 60 / 60)
    cond do
      hours == 0 -> "UTC"
      hours < 0 -> "GMT#{hours}"
      hours > 0 -> "GMT+#{hours}"
    end
  end
end
