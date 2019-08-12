defmodule Ask.BadRequest do
  defexception plug_status: 403, message: "bad request", conn: nil

  def exception(_) do
    %Ask.BadRequest{}
  end
end

defimpl Plug.Exception, for: Ask.BadRequest do
  def status(_), do: 400
end
