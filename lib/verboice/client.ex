defmodule Verboice.Client do
  alias __MODULE__
  defstruct [:base_url, :username, :password]

  def new(url, username, password) do
    %Client{base_url: url, username: username, password: password}
  end

  def call(client, params) do
    headers = []
    options = [basic_auth: {client.username, client.password}]
    url = :hackney_url.make_url(client.base_url, "/api/call", params)
    :hackney.get(url, headers, "", options)
  end

end
