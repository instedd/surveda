defmodule Ask.Runtime.VerboiceChannel do
  alias __MODULE__
  use Ask.Web, :model
  alias Ask.{Repo, Respondent, Channel}
  alias Ask.Runtime.{Broker, Flow}
  alias Ask.Router.Helpers
  import Plug.Conn
  @behaviour Ask.Runtime.ChannelProvider
  defstruct [:client, :channel_name]

  def new(channel) do
    channel_name = channel.settings["verboice_channel"]
    client = create_client(channel.user_id)
    %VerboiceChannel{client: client, channel_name: channel_name}
  end

  def oauth2_authorize(code, redirect_uri, _callback_url) do
    verboice_config = Application.get_env(:ask, Verboice)
    guisso_config = verboice_config[:guisso]

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
    verboice_config = Application.get_env(:ask, Verboice)
    guisso_config = verboice_config[:guisso]

    client = OAuth2.Client.new([
      token: access_token,
      client_id: guisso_config[:client_id],
      token_url: "#{guisso_config[:base_url]}/oauth2/token",
    ])

    client = OAuth2.Client.refresh_token!(client,
      client_secret: guisso_config[:client_secret])

    client.token
  end

  def gather(respondent, prompt) do
    "<Gather action=\"#{callback_url(respondent)}\">#{say_or_play(prompt)}</Gather>"
  end

  def say_or_play(%{"audio_source" => "upload", "audio_id" => audio_id}) do
    "<Play>#{Helpers.audio_delivery_url(Ask.Endpoint, :show, audio_id)}</Play>"
  end

  def say_or_play(%{"audio_source" => "tts", "text" => text}) do
    "<Say>#{text}</Say>"
  end

  defp create_client(user_id) do
    verboice_config = Application.get_env(:ask, Verboice)
    oauth_token = Ask.OAuthTokenServer.get_token "verboice", user_id
    Verboice.Client.new(verboice_config[:base_url], oauth_token)
  end

  def sync_channels(user_id) do
    client = create_client(user_id)

    case client |> Verboice.Client.get_channels do
      {:ok, channel_names} ->
        sync_channels(user_id, channel_names)

      _ -> :error
    end
  end

  def sync_channels(user_id, channel_names) do
    user = Ask.User |> Repo.get!(user_id)
    channels = user |> assoc(:channels) |> where([c], c.provider == "verboice") |> Repo.all

    channels |> Enum.each(fn channel ->
      exists = channel_names |> Enum.any?(fn name -> channel.settings["verboice_channel"] == name end)
      if !exists do
        channel |> Repo.delete
      end
    end)


    channel_names |> Enum.each(fn name ->
      exists = channels |> Enum.any?(fn channel -> channel.settings["verboice_channel"] == name end)
      if !exists do
        user
        |> Ecto.build_assoc(:channels)
        |> Channel.changeset(%{name: name, type: "ivr", provider: "verboice", settings: %{"verboice_channel" => name}})
        |> Repo.insert
      end
    end)
  end

  def callback(conn, params = %{"respondent" => respondent_id}) do
    respondent = Respondent |> Repo.get(respondent_id)

    reply = case respondent do
      nil ->
        "<Response><Hangup/></Response>"

      _ ->
        response = case params["Digits"] do
          nil -> Flow.Message.answer()
          digits -> Flow.Message.reply(digits)
        end

        case Broker.sync_step(respondent, response) do
          {:prompt, prompt} ->
            "<Response>#{gather(respondent, prompt)}#{gather(respondent, prompt)}#{gather(respondent, prompt)}</Response>"
          {:end, {:prompt, prompt}} ->
            "<Response>#{say_or_play(prompt)}<Hangup/></Response>"
          :end ->
            "<Response><Hangup/></Response>"
        end
    end

    conn
    |> put_resp_content_type("text/xml")
    |> send_resp(200, reply)
  end

  def callback(conn, _) do
    conn
    |> put_resp_content_type("text/xml")
    |> send_resp(200, "<Response><Hangup/></Response>")
  end

  def callback_url(respondent) do
    Ask.Router.Helpers.callback_url(Ask.Endpoint, :callback, "verboice", respondent: respondent.id)
  end

  defimpl Ask.Runtime.Channel, for: Ask.Runtime.VerboiceChannel do
    def can_push_question?(_), do: false
    def ask(_, _, _), do: throw(:not_implemented)
    def prepare(_, _), do: :ok

    def setup(channel, respondent) do
      channel.client
      |> Verboice.Client.call(address: respondent.sanitized_phone_number,
                              channel: channel.channel_name,
                              callback_url: VerboiceChannel.callback_url(respondent))
    end
  end
end
