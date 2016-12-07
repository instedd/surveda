defmodule Ask.Runtime.VerboiceChannel do
  alias __MODULE__
  alias Ask.{Repo, Respondent}
  alias Ask.Runtime.{Broker, Flow}
  alias Ask.Router.Helpers
  import Plug.Conn
  @behaviour Ask.Runtime.ChannelProvider
  defstruct [:client, :channel_name]

  def new(channel) do
    url = channel.settings["url"]
    username = channel.settings["username"]
    password = channel.settings["password"]
    channel_name = channel.settings["channel"]
    %VerboiceChannel{client: Verboice.Client.new(url, username, password), channel_name: channel_name}
  end

  def oauth2_authorize(_code, _redirect_uri, _callback_url), do: throw(:not_implemented)
  def oauth2_refresh(_access_token), do: throw(:not_implemented)

  def gather(respondent, %{"audio_source" => "upload", "audio_id" => audio_id}) do
    "<Gather action=\"#{callback_url(respondent)}\"><Play>#{Helpers.audio_delivery_url(Ask.Endpoint, :show, audio_id)}</Play></Gather>"
  end

  def gather(respondent, %{"audio_source" => "tts", "text" => text}) do
    "<Gather action=\"#{callback_url(respondent)}\"><Say>#{text}</Say></Gather>"
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
          {:end, {:prompt, text}} ->
            # TODO: this assumes prompt is always text, because this can
            # only happen for reproducing the "quota-completed message",
            # which can't specify an audio yet
            "<Response><Say>#{text}</Say><Hangup/></Response>"
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

    def setup(channel, respondent) do
      channel.client
      |> Verboice.Client.call(address: respondent.sanitized_phone_number,
                              channel: channel.channel_name,
                              callback_url: VerboiceChannel.callback_url(respondent))
    end
  end
end
