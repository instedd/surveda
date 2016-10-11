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
end
