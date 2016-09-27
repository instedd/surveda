defmodule Ask.Runtime.NuntiumChannel do
  @behaviour Ask.Runtime.ChannelProvider
  alias Ask.Runtime.NuntiumChannel
  defstruct [:oauth_token, :name, :settings]

  def new(channel) do
    oauth_token = Ask.Repo.get_by(Ask.OAuthToken, provider: "nuntium", user_id: channel.user_id) |> Ask.OAuthToken.access_token
    name = channel.name
    %NuntiumChannel{oauth_token: oauth_token, name: name, settings: channel.settings}
  end

  def oauth2_authorize(code, redirect_uri) do
    nuntium_config = Application.get_env(:ask, Nuntium)
    guisso_config = nuntium_config[:guisso]

    client = OAuth2.Client.new([
      client_id: guisso_config[:client_id],
      redirect_uri: redirect_uri,
      token_url: "#{guisso_config[:base_url]}/oauth2/token",
    ])

    client = OAuth2.Client.get_token!(client,
      code: code,
      client_secret: guisso_config[:client_secret],
      token_type: "bearer")

    client.token
  end

  def oauth2_refresh(access_token) do
    access_token
  end

  defimpl Ask.Runtime.Channel, for: Ask.Runtime.NuntiumChannel do
    def ask(channel, phone_number, prompts) do
      nuntium_config = Application.get_env(:ask, Nuntium)
      messages = prompts |> Enum.map(fn prompt ->
        %{
          to: "sms://#{phone_number}",
          body: prompt,
          suggested_channel: channel.name,
        }
      end)
      Nuntium.Client.new(nuntium_config[:base_url], channel.oauth_token)
      |> Nuntium.Client.send_ao(messages)
    end
  end
end
