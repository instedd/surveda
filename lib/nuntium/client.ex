defmodule Nuntium.Client do
  alias Ask.SurvedaMetrics
  alias Nuntium.Client
  defstruct [:base_url, :oauth2_client]

  # @type t :: %Client{}

  # @spec new(String.t, OAuth2.AccessToken.t) :: t
  def new(url, token) do
    oauth2_client = OAuth2.Client.new(token: token)
    %Client{base_url: url, oauth2_client: oauth2_client}
  end

  # @spec send_ao(t, String.t) :: any()
  def send_ao(client, account, messages) do
    url = "#{client.base_url}/api/ao_messages.json?#{URI.encode_query([account: account])}"
    response = client.oauth2_client
               |> OAuth2.Client.post(url, messages)
    {_, response_body} = response
    SurvedaMetrics.increment_counter_with_label(:surveda_nuntium_enqueue, [response_body.status_code])
    parse_response(response)
  end

  def application_update(client, account, app = %{}) do
    url = "#{client.base_url}/api/applications/me?#{URI.encode_query([account: account])}"
    client.oauth2_client
    |> OAuth2.Client.put(url, app)
    |> parse_response
  end

  def channel_update(client, account, channel_name, settings = %{}) do
    url = "#{client.base_url}/api/channels/#{channel_name}.json?#{URI.encode_query([account: account, application: "-"])}"
    client.oauth2_client
    |> OAuth2.Client.put(url, settings)
    |> parse_response
  end

  def get_accounts(client) do
    url = "#{client.base_url}/api/accounts.json"
    client.oauth2_client
    |> OAuth2.Client.get(url)
    |> parse_response
  end

  def get_channels(client, account) do
    url = "#{client.base_url}/api/channels.json?#{URI.encode_query([account: account])}"
    client.oauth2_client
    |> OAuth2.Client.get(url)
    |> parse_response
  end

  def get_channel(client, account, channel_name) do
    url = "#{client.base_url}/api/channels/#{channel_name}.json?#{URI.encode_query([account: account])}"
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
