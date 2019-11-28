defmodule Ask.LogHelper do
  defmacro __using__(_) do
    quote do
      import Ask.LogHelper
    end
  end

  defmacro without_logging(do: block) do
    quote do
      Logger.remove_backend(:console)

      try do
        unquote(block)
      after
        Logger.add_backend(:console)
      end
    end
  end
end
