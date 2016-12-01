defmodule Nuntium.Client do
  alias Nuntium.Client
  defstruct [:base_url, :oauth2_client]

  # @type t :: %Client{}

  # @spec new(String.t, OAuth2.AccessToken.t) :: t
  def new(url, token) do
    oauth2_client = OAuth2.Client.new(token: token)
    %Client{base_url: url, oauth2_client: oauth2_client}
  end

  # @spec send_ao(t, String.t) :: any()
  def send_ao(client, messages) do
    url = "#{client.base_url}/api/ao_messages.json"
    OAuth2.Client.post(client.oauth2_client, url, messages)
  end

  def application_update(client, app = %{}) do
    url = "#{client.base_url}/api/applications/me"
    OAuth2.Client.put(client.oauth2_client, url, app)
  end

  def get_accounts(client) do
    url = "#{client.base_url}/api/accounts.json"
    client.oauth2_client
    |> OAuth2.Client.get(url)
    |> parse_response
  end

  def get_channels(client, account) do
    url = "#{client.base_url}/api/channels.json?account=#{account}"
    client.oauth2_client
    |> OAuth2.Client.get(url)
    |> parse_response
  end

  defp parse_response(response) do
    case response do
      {:ok, response = %{status_code: 200}} ->
        {:ok, response.body}
      {:ok, response} ->
        {:error, response.status_code}
      {:error, %OAuth2.Error{reason: reason}} ->
        {:error, reason}
    end
  end
end
