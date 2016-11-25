defmodule Verboice.Client do
  alias __MODULE__
  defstruct [:base_url, :oauth2_client]

  def new(url, token) do
    oauth2_client = OAuth2.Client.new(token: token)
    %Client{base_url: url, oauth2_client: oauth2_client}
  end

  def call(client, params) do
    headers = []
    options = [basic_auth: {client.username, client.password}]
    url = :hackney_url.make_url(client.base_url, "/api/call", params)
    :hackney.get(url, headers, "", options)
  end

  def get_channels(client) do
    url = URI.merge(client.base_url, "/api/channels") |> URI.to_string
    case OAuth2.Client.get(client.oauth2_client, url) do
      {:ok, response = %{status_code: 200}} ->
        {:ok, response.body}
      {:ok, response} ->
        {:error, response.status_code}
      {:error, %OAuth2.Error{reason: reason}} ->
        {:error, reason}
    end
  end

end
