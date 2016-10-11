defmodule Ask.Runtime.NuntiumChannel do
  @behaviour Ask.Runtime.ChannelProvider
  alias Ask.Runtime.{Broker, NuntiumChannel}
  alias Ask.{Repo, Respondent}
  import Ecto.Query
  defstruct [:oauth_token, :name, :settings]

  def new(channel) do
    oauth_token = Ask.OAuthTokenServer.get_token "nuntium", channel.user_id
    name = channel.name
    %NuntiumChannel{oauth_token: oauth_token, name: name, settings: channel.settings}
  end

  def oauth2_authorize(code, redirect_uri, callback_url) do
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

    # Update the Nuntium app to setup the callback URL
    nuntium_config = Application.get_env(:ask, Nuntium)
    Nuntium.Client.new(nuntium_config[:base_url], client.token)
    |> Nuntium.Client.application_update(%{
      interface: %{
        type: "http_get_callback",
        url: callback_url
      }
    })

    client.token
  end

  def oauth2_refresh(access_token) do
    nuntium_config = Application.get_env(:ask, Nuntium)
    guisso_config = nuntium_config[:guisso]

    client = OAuth2.Client.new([
      token: access_token,
      client_id: guisso_config[:client_id],
      token_url: "#{guisso_config[:base_url]}/oauth2/token",
    ])

    client = OAuth2.Client.refresh_token!(client,
      client_secret: guisso_config[:client_secret])

    client.token
  end

  def callback(conn, %{"from" => from, "body" => body}) do
    %URI{host: phone_number} = URI.parse(from)

    respondent = Repo.one(from r in Respondent,
      where: r.phone_number == ^phone_number and r.state == "active",
      order_by: [desc: r.updated_at],
      limit: 1)

    reply = case respondent do
      nil ->
        []
      _ ->
        case Broker.sync_step(respondent, body) do
          {:prompt, prompt} ->
            [%{"to": from, "body": prompt}]
          :end ->
            []
        end
    end

    Phoenix.Controller.json(conn, reply)
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
