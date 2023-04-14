defmodule Ask.TimeUtil do
  @months %{
    1 => "Jan",
    2 => "Feb",
    3 => "Mar",
    4 => "Apr",
    5 => "May",
    6 => "Jun",
    7 => "Jul",
    8 => "Aug",
    9 => "Sep",
    10 => "Oct",
    11 => "Nov",
    12 => "Dec",
  }

  def format(ecto_timestamp, offset_seconds, offset_label) do
    {{year, month, day}, {hour, min, sec}} = to_ymdhms(ecto_timestamp, offset_seconds)
    "#{year}-#{pad2(month)}-#{pad2(day)} #{pad2(hour)}:#{pad2(min)}:#{pad2(sec)} #{offset_label}"
  end

  # Applies offset and formats datetime as `Timex.format!("%b %e, %Y %H:%M #{tz_offset}", :strftime)`.
  # There are no reasons to not use Timex.format unless you need raw performance and make lots of
  # repeating calls in a tight loop (eg. exporting a CSV) which is sole reason that method exists.
  def format2(ecto_timestamp, offset_seconds, offset_label) do
    {{year, month, day}, {hour, min, _sec}} = to_ymdhms(ecto_timestamp, offset_seconds)
    "#{Map.get(@months, month)} #{pad2(day, " ")}, #{year} #{pad2(hour)}:#{pad2(min)} #{offset_label}"
  end

  defp to_ymdhms(ecto_timestamp, offset_seconds) do
    timestamp_in_seconds =
      ecto_timestamp
      |> Timex.to_erl()
      |> :calendar.datetime_to_gregorian_seconds()

    (timestamp_in_seconds + offset_seconds)
    |> :calendar.gregorian_seconds_to_datetime()
  end

  defp pad2(s, char \\ "0"), do: Integer.to_string(s) |> String.pad_leading(2, char)
end
