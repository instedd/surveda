defmodule AskWeb.UnauthorizedError do
  defexception plug_status: 403, message: "unauthorized", conn: nil

  def exception(_) do
    %AskWeb.UnauthorizedError{}
  end
end

defimpl Plug.Exception, for: AskWeb.UnauthorizedError do
  def status(_), do: 403
  def actions(_), do: [%{label: "UnauthorizedError", handler: {IO, :puts, "UnauthorizedError"}}]
end
