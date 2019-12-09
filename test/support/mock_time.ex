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
      setup :verify_on_exit!
    end
  end
end