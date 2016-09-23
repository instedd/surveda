defmodule Ask.UnauthorizedError do
  defexception plug_status: 403, message: "unauthorized", conn: nil

  def exception(opts) do
    conn   = Keyword.fetch!(opts, :conn)
    path   = "/" <> Enum.join(conn.path_info, "/")

    %Ask.UnauthorizedError{
      message: "not authorized for #{conn.method} #{path}",
      conn: conn
    }
  end
end

defimpl Plug.Exception, for: Ask.UnauthorizedError do
  def status(_), do: 403
end
