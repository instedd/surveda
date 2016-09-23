defmodule Ask.UnauthorizedError do
end

defimpl Plug.Exception, for: Ask.UnauthorizedError do
  def status(_), do: 403
end
