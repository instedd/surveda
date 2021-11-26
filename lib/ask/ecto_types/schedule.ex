defmodule Ask.Schedule do
  @moduledoc """
  A custom type to map schedules to the database

  This type contains an Ask.DayOfWeek, start and end time for each day, and
  a list of blocked days such as holidays
  """

  @behaviour Ecto.Type

  alias __MODULE__
  alias Ask.{DayOfWeek, ScheduleError, SystemTime}

  defstruct [:day_of_week, :start_time, :end_time, :blocked_days, :timezone, :start_date, :end_date]

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
  def cast(%{start_date: start_date} = schedule) when is_binary(start_date) do
    cast(%{schedule | start_date: Date.from_iso8601!(start_date)})
  end
  def cast(%{end_date: end_date} = schedule) when is_binary(end_date) do
    cast(%{schedule | end_date: Date.from_iso8601!(end_date)})
  end
  def cast(%{day_of_week: day_of_week, start_time: start_time, end_time: end_time, blocked_days: blocked_days, timezone: timezone, start_date: start_date, end_date: end_date}) do
    case DayOfWeek.cast(day_of_week) do
      :error -> :error
      {:ok, dow} ->
        {:ok, %Schedule{day_of_week: dow, start_time: start_time, end_time: end_time, blocked_days: cast_blocked_days(blocked_days), timezone: timezone, start_date: start_date, end_date: end_date}}
    end
  end
  def cast(%{} = map) do
    cast(%{
      day_of_week: map["day_of_week"],
      start_time: map["start_time"],
      end_time: map["end_time"],
      blocked_days: map["blocked_days"],
      timezone: map["timezone"],
      start_date: map["start_date"],
      end_date: map["end_date"]
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
  def load(nil), do: {:ok, always()}
  def load(_), do: :error

  def load!(schedule) do
    case load(schedule) do
      {:ok, schedule} -> schedule
      :error -> raise "Schedule load error #{inspect(schedule)}"
    end
  end

  def dump(%Schedule{day_of_week: day_of_week}=schedule) do
    {:ok, day_of_week}= DayOfWeek.dump(day_of_week)
    schedule = %{schedule |
      day_of_week: day_of_week,
      blocked_days: schedule.blocked_days || []
    }
    Poison.encode(schedule)
  end
  def dump(_), do: :error

  def dump!(schedule) do
    case dump(schedule) do
      {:ok, schedule} -> schedule
      :error -> raise "Schedule dump error #{inspect(schedule)}"
    end
  end

  def validate(schedule) do
    if schedule.start_time && schedule.end_time && schedule.start_time >= schedule.end_time do
      :error
    else
      :ok
    end
  end

  def intersect?(%Schedule{day_of_week: days, start_time: start_time, end_time: end_time, timezone: timezone, blocked_days: blocked_days, start_date: start_date}, %DateTime{} = date_time) do
    date_time = date_time
    |> Timex.to_datetime(timezone)

    time = DateTime.to_time(date_time)
    date = DateTime.to_date(date_time)

    DayOfWeek.intersect?(days, DayOfWeek.from(date_time))
      && !Enum.member?(blocked_days, date_time |> Timex.to_date)
      && Time.compare(start_time, time) != :gt
      && Time.compare(end_time, time) != :lt
      && (!start_date || Date.compare(start_date, date) != :gt)
  end

  def business_day(), do:
    %Schedule{
      day_of_week: %DayOfWeek{sun: false, mon: true, tue: true, wed: true, thu: true, fri: true, sat: false},
      start_time: ~T[09:00:00],
      end_time: ~T[18:00:00],
      blocked_days: [],
      timezone: default_timezone()
    }

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

  # Find the beggining of the first active window, going forward
  def next_available_date_time(%Schedule{end_date: end_date, start_date: start_date} = schedule, %DateTime{} = from_date_time \\ SystemTime.time.now) do
    from_date_time = select_from_date_time(from_date_time, start_date)
    backward = false
    limit = end_date
    reversible_next_available_date_time(schedule, from_date_time, backward, limit)
  end

  defp select_from_date_time(from_date_time, nil = _start_date), do: from_date_time

  defp select_from_date_time(from_date_time, start_date) do
    # 1 -- the from_date_time comes after the start_date
    if Timex.compare(from_date_time, start_date) > 0 do
      from_date_time
    else
      start_date
    end
  end

  # Find the ending of the last active window, going backward from the last minute of the end_date
  def last_window_ends_at(%{end_date: nil} = _schedule), do: nil
  def last_window_ends_at(%{end_date: end_date, start_date: start_date} = schedule) do
    backward = true
    limit = start_date
    from_date_time = Date.add(end_date, 1)
    reversible_next_available_date_time(schedule, from_date_time, backward, limit)
  end

  # Why do we need this reversible function? Because we need to calculate:
  # 1. The start_time of the first active window (backward = false)
  # 2. The end_time of the last active window (backward = true)
  # And the logic for doing that is pretty much the same.
  defp reversible_next_available_date_time(schedule, date_time, backward, limit) do
    date_time = Timex.to_datetime(date_time, schedule.timezone)

    # TODO: Remove the necessity of converting this to erl dates
    {erl_date, erl_time} = Timex.to_erl(date_time)
    {:ok, time} = Time.from_erl(erl_time)

    selected_datetime = if day_of_week_available?(schedule, erl_date) && compare_time(schedule, time) == :inside do
      date_time
    else
      selected_date = select_available_date(schedule, erl_date, time, backward, limit)
      select_time_for_date(schedule, selected_date, backward)
    end

    selected_datetime
    |> Timex.Timezone.convert("Etc/UTC")
  end

  def select_time_for_date(schedule, erl_date, backward) do
    if backward, do: at_end_time_erl(schedule, erl_date), else: at_start_time(schedule, erl_date)
  end

  def select_available_date(schedule, erl_date, time, backward, limit) do
    date_to_return = if day_of_week_available?(schedule, erl_date) do
      pick_date_based_on_time_and_direction(compare_time(schedule, time), backward)
    else
      :next_date
    end

    case date_to_return do
      :given_date -> erl_date
      :next_date -> next_available_date(schedule, erl_date, backward, limit)
    end
  end

  defp pick_date_based_on_time_and_direction(:before = _time_is, true = _backward), do: :next_date
  defp pick_date_based_on_time_and_direction(:before = _time_is, false = _backward), do: :given_date
  defp pick_date_based_on_time_and_direction(:after = _time_is, true = _backward), do: :given_date
  defp pick_date_based_on_time_and_direction(:after = _time_is, false = _backward), do: :next_date

  def at_end_time(%Schedule{end_time: end_time, timezone: timezone}, %DateTime{} = date_time) do
    {erlang_date, _} = date_time |> Timex.Timezone.convert(timezone) |> Timex.to_erl
    erlang_time = end_time |> Time.to_erl
    Timex.Timezone.resolve(timezone, {erlang_date, erlang_time})
  end

  def remove_start_date(schedule) do
    Map.put(schedule, :start_date, nil)
  end

  def remove_end_date(schedule) do
    Map.put(schedule, :end_date, nil)
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

  defp at_end_time_erl(schedule, erl_date) do
    erl_time = schedule.end_time |> Time.to_erl
    Timex.Timezone.resolve(schedule.timezone, {erl_date, erl_time})
  end

  defp next_available_date(schedule, erl_date, backward, limit) do
    raise_if_date_exceeds_limit(erl_date, backward, limit)

    shift_days = if backward, do: -1, else: 1
    next_date = Date.from_erl!(erl_date) |> Date.add(shift_days) |> Timex.to_erl

    if day_of_week_available?(schedule, next_date) do
      next_date
    else
      next_available_date(schedule, next_date, backward, limit)
    end
  end

  defp raise_if_date_exceeds_limit(date_time, backward, limit), do:
    if date_exceeds_limit?(date_time, backward, limit), do:
      raise_date_exceeds_limit(backward)

  defp raise_date_exceeds_limit(true = _backward), do:
    raise ScheduleError, "last active window not found"

  defp raise_date_exceeds_limit(false = _backward), do:
    raise ScheduleError, "next active window not found"

  defp date_exceeds_limit?(_date_time, _backward, nil = _limit), do: false

  defp date_exceeds_limit?(date_time, backward, limit) do
    comparison = Timex.compare(date_time, limit)
    if backward do
      # -1 -- date_time comes before the limit
      comparison < 0
    else
      # 1 -- date_time comes after the limit
      comparison > 0
    end
  end

  defp day_of_week_available?(%Schedule{day_of_week: day_of_week, blocked_days: blocked_days}, erl_date) do
    date = Date.from_erl!(erl_date)
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
      end && !Enum.member?(blocked_days, date)
    end
  end

  def any_day_selected?(%Schedule{day_of_week: day_of_week}) do
    DayOfWeek.any_day_selected?(day_of_week)
  end

  def adjust_date_to_timezone(%Schedule{} = schedule, date) do
    date
    |> Timex.Timezone.convert(schedule.timezone)
  end

  def timezone_offset_in_seconds(%Schedule{} = schedule) do
    schedule.timezone
    |> Timex.Timezone.get
    |> Timex.Timezone.total_offset
  end

  def timezone_offset(%Schedule{} = schedule) do
    offset = timezone_offset_in_seconds(schedule)
    hours = round(offset / 60 / 60)
    cond do
      hours == 0 -> "UTC"
      hours < 0 -> "GMT#{hours}"
      hours > 0 -> "GMT+#{hours}"
    end
  end
end
