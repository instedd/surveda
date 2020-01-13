defmodule Ask.Logger do
  require Logger

  def error(msg) do
    if should_log() do
      Logger.error(msg)
    else
      [:red, "\n", msg, ": ", Exception.format_stacktrace()] |> IO.ANSI.format |> IO.puts
    end
  end

  def warn(msg) do
    if should_log() do
      Logger.warn msg
    end
  end

  def info(msg) do
    if should_log() do
      Logger.info msg
    end
  end

  def debug(msg) do
    if should_log() do
      Logger.debug msg
    end
  end

  defp should_log do
    Mix.env != :test
  end

end
