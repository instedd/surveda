defmodule AskWeb.ConflictError do
  defexception plug_status: 405, message: "not allowed", conn: nil

  def exception(_) do
    %AskWeb.ConflictError{}
  end
end

defimpl Plug.Exception, for: AskWeb.ConflictError do
  def status(_), do: 409
  def actions(_), do: [%{label: "ConflictError", handler: {IO, :puts, "ConflictError"}}]
end
