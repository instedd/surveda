defmodule Ask.TimeHelpers do
  defmacro __using__(_) do
    quote do
      use Ask.MockTime
      alias Ask.SystemTime

      defp mock_time(time) do
        Ask.TimeMock
        |> stub(:now, fn () -> time end)
        time
      end

      defp set_current_time(time) do
        {:ok, now, _} = DateTime.from_iso8601(time)
        mock_time(now)
      end

      defp set_actual_time, do: mock_time(Timex.now)

      defp time_passes(diff), do:
        SystemTime.time.now
        |> Timex.shift(diff)
        |> mock_time

    end
  end
end
