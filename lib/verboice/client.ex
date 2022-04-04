defmodule Verboice.Client do
  alias Ask.SurvedaMetrics
  alias __MODULE__
  defstruct [:base_url, :oauth2_client]

  def new(url, token) do
    oauth2_client = OAuth2.Client.new(token: token)
    %Client{base_url: url, oauth2_client: oauth2_client}
  end

  defp status_or_reason(%OAuth2.Error{reason: reason}), do: reason
  defp status_or_reason(%{status_code: status_code}), do: status_code

  def call(client, params) do
    url = "#{URI.merge(client.base_url, "api/call")}?#{URI.encode_query(params)}"

    response =
      client.oauth2_client
      |> OAuth2.Client.get(url)

    {_, response_body} = response

    SurvedaMetrics.increment_counter_with_label(:surveda_verboice_enqueue, [
      status_or_reason(response_body)
    ])

    parse_response(response)
  end

  def call_state(client, call_id) do
    url = "#{URI.merge(client.base_url, "api/calls/#{call_id}/state.json")}"

    client.oauth2_client
    |> OAuth2.Client.get(url)
    |> parse_response
  end

  def cancel(client, call_id) do
    url = "#{URI.merge(client.base_url, "api/calls/#{call_id}/cancel.json")}"

    client.oauth2_client
    |> OAuth2.Client.post(url)
    |> parse_response
  end

  def get_channels(client) do
    url = URI.merge(client.base_url, "/api/channels/all") |> URI.to_string()

    client.oauth2_client
    |> OAuth2.Client.get(url)
    |> parse_response
  end

  def get_channel(client, channel_id) do
    url = URI.merge(client.base_url, "/api/channels/all/#{channel_id}") |> URI.to_string()

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
