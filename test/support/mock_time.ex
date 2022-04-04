defmodule Ask.MockTime do
  @moduledoc """

  This module configurtes `Ask.TimeMock` module as application_env under the key :time.
  All places where `SystemTime.time` is being used will get `Ask.TimeMock`

  Configuring tests:
    For using this configuration for:
      - a single test, tag your test with `@tag :time_mock`
      - a whole module use: `@moduletag :time_mock`
      - a whole describe section use: `@describetag :time_mock`
  """

  use ExUnit.CaseTemplate

  setup context do
    if context[:time_mock] do
      Application.put_env(:ask, :time, Ask.TimeMock)

      on_exit(fn ->
        Application.delete_env(:ask, :time)
      end)
    end

    :ok
  end

  using do
    quote do
      import Mox
      alias Ask.SystemTime

      setup :verify_on_exit!
      setup :set_mox_from_context

      defp mock_time(time) do
        Ask.TimeMock
        |> stub(:now, fn -> time end)

        time
      end

      defp set_current_time(time) do
        {:ok, now, _} = DateTime.from_iso8601(time)
        mock_time(now)
      end

      defp set_actual_time, do: mock_time(Timex.now())

      defp time_passes(diff),
        do:
          SystemTime.time().now
          |> Timex.shift(diff)
          |> mock_time
    end
  end
end
