defmodule Ask.ConflictError do
  defexception plug_status: 405, message: "not allowed", conn: nil

  def exception(_) do
    %Ask.ConflictError{}
  end
end

defimpl Plug.Exception, for: Ask.ConflictError do
  def status(_), do: 409
end
