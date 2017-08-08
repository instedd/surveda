defmodule CSV.Helper do
  import Plug.Conn
  @chunk_lines 100

  alias Ask.Repo

  def csv_stream(conn, rows, filename) do
    conn = conn
      |> put_resp_content_type("text/csv")
      |> put_resp_header("content-disposition", "attachment; filename=\"#{filename}\"")
      |> send_chunked(200)

    Repo.transaction(fn() ->
      rows
      |> CSV.encode
      |> Stream.chunk(@chunk_lines, @chunk_lines, [])
      |> Enum.reduce(conn, fn (lines, conn) ->
        {:ok, conn} = chunk(conn, lines)
        conn
      end)
    end)

    conn
  end
end
