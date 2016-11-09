defmodule Ask.LandingController do
  use Ask.Web, :controller

  plug :put_layout, false

  def index(conn, _params) do
    render conn, "index.html"
  end
end
