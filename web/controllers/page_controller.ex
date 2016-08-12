defmodule Ask.PageController do
  use Ask.Web, :controller

  plug Addict.Plugs.Authenticated when action in [:index]

  def index(conn, _params) do
    user = Addict.Helper.current_user(conn)
    render conn, "index.html", user: user
  end
end
