defmodule Ask.ShortLinkController do
  use Ask.Web, :controller
  require Plug.Router

  alias Ask.ShortLink

  def access(conn, %{"hash" => hash}) do
    link = ShortLink
    |> Repo.get_by(hash: hash)

    conn = conn
    |> assign(:skip_auth, true)

    {path, query_string} = case :binary.split(link.target, "?", [:global]) do
      [path, query_string] -> {path, query_string}
      [path] -> {path, ""}
    end

    conn = %{conn |
      request_path: path,
      path_info: split_path(path),
      params: %{},
      path_params: %{},
      private: %{},
      req_headers: [],
      query_string: query_string,
      query_params: %Plug.Conn.Unfetched{aspect: :query_params}
    }

    Ask.Endpoint.call(conn, [])
  end

  # Copied from Plug.Adapters.Cowboy.Conn
  defp split_path(path) do
    segments = :binary.split(path, "/", [:global])
    for segment <- segments, segment != "", do: segment
  end
end
