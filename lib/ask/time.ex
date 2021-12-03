defmodule Ask.SystemTime do
  def time(), do: Application.get_env(:ask, :time, Ask.RealTime)
end

defmodule Ask.RealTime do
  @callback now() :: DateTime
  def now() do
    DateTime.utc_now
  end
end
