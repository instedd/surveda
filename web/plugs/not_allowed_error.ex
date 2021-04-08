defmodule Ask.NotAllowedError do
  defexception plug_status: 405, message: "not allowed", conn: nil

  def exception(_) do
    %Ask.NotAllowedError{}
  end
end

defimpl Plug.Exception, for: Ask.NotAllowedError do
  def status(_), do: 405
end
