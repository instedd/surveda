defmodule Ask.Static do
  use Plug.Builder

  @static_paths ~w(css fonts images js favicon.ico robots.txt)

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phoenix.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :ask,
    gzip: false,
    only: @static_paths
  
  plug :not_found

  def not_found(conn, _) do
    case conn.path_info do
      [] -> conn
      [path | _] -> case Enum.member?(@static_paths, path) do
        true -> conn |> send_resp(404, "not found") |> halt
        _ -> conn
      end
    end
  end
end