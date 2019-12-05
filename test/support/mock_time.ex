defmodule Ask.MockTime do
  use ExUnit.CaseTemplate

  setup do
    Application.put_env(:ask, :time, Ask.TimeMock)
    on_exit(fn -> Application.delete_env(:ask, :time) end)
  end

  using do
    quote do
      import Mox
      setup :verify_on_exit!
    end
  end
end