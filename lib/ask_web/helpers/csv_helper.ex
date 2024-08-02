defmodule CSV.Helper do
  import Plug.Conn
  @chunk_lines 100
  @long_connection_timeout 3_600_000 # in ms

  defp connection_timeout(%Plug.Conn{adapter: adapter} = conn, timeout) do
    case adapter do
      {Plug.Cowboy.Conn, request} -> :cowboy_req.cast({:set_options, %{ idle_timeout: timeout }}, request)
      _ -> :ok
    end
    conn
  end

  # TODO: we now want to have long timeouts by default for the CSV files we generate
  # but we eventually may want to change this to use the default timeout except for
  # some specific CSV files we know take long
  def csv_stream(conn, rows, filename, timeout \\ @long_connection_timeout) do
    conn =
      conn
      |> connection_timeout(timeout)
      |> put_resp_content_type("text/csv")
      |> put_resp_header("content-disposition", "attachment; filename=\"#{filename}\"")
      |> send_chunked(200)

    rows
    |> CSV.encode()
    |> Stream.chunk_every(@chunk_lines)
    |> Enum.reduce(conn, fn lines, conn ->
      {:ok, conn} = chunk(conn, lines)
      conn
    end)
  end
end
