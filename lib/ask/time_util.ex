defmodule Ask.TimeUtil do
  def format(ecto_timestamp, offset_seconds, offset_label) do
    timestamp_in_seconds =
      ecto_timestamp
      |> Ecto.DateTime.to_erl
      |> :calendar.datetime_to_gregorian_seconds

    {{year, month, day}, {hour, min, sec}} =
      (timestamp_in_seconds + offset_seconds)
      |> :calendar.gregorian_seconds_to_datetime

    "#{year}-#{pad2(month)}-#{pad2(day)} #{pad2(hour)}:#{pad2(min)}:#{pad2(sec)} #{offset_label}"
  end

  defp pad2(s), do: Integer.to_string(s) |> String.pad_leading(2, "0")
end
