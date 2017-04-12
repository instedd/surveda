defmodule Ask.Runtime.VerboiceChannel do
  alias __MODULE__
  use Ask.Web, :model
  alias Ask.{Repo, Respondent, Channel}
  alias Ask.Runtime.{Broker, Flow, Reply}
  alias Ask.Router.Helpers
  import Plug.Conn
  import XmlBuilder
  @behaviour Ask.Runtime.ChannelProvider
  defstruct [:client, :channel_name]

  def new(channel) do
    channel_name = channel.settings["verboice_channel"]
    client = create_client(channel.user_id, channel.base_url)
    %VerboiceChannel{client: client, channel_name: channel_name}
  end

  def oauth2_authorize(code, redirect_uri, base_url) do
    verboice_config = Ask.Config.provider_config(Verboice, base_url)
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

  def oauth2_refresh(access_token, base_url) do
    verboice_config = Ask.Config.provider_config(Verboice, base_url)
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

  def gather(respondent, prompts = [prompt, _ | _]) do
    [say_or_play(prompt) | gather(respondent, tl(prompts))]
  end

  def gather(respondent, prompts) do
    [
      # We need to set finishOnKey="" so that when a user presses '#'
      # the current question doesn't give a "timeout" from Verboice,
      # and '#' is sent here so it can be considered a refusal, a valid
      # option, etc.
      element(:Gather, %{action: callback_url(respondent), finishOnKey: ""}, [
        say_or_play(prompts)
      ]),
      element(:Redirect, no_reply_callback_url(respondent))
    ]
  end

  def say_or_play([prompt]) do
    [say_or_play(prompt)]
  end

  def say_or_play([prompt | prompts]) do
    [say_or_play(prompt) | say_or_play(prompts)]
  end

  def say_or_play(%{"audio_source" => "upload", "audio_id" => audio_id}) do
    element(:Play, Helpers.audio_delivery_url(Ask.Endpoint, :show, audio_id))
  end

  def say_or_play(%{"audio_source" => "tts", "text" => text}) do
    element(:Say, text)
  end

  defp hangup do
    element(:Hangup)
  end

  defp response(content) when is_list(content) do
    element(:Response, content)
  end

  defp response(content) do
    element(:Response, [content])
  end

  defp create_client(user_id, base_url) do
    oauth_token = Ask.OAuthTokenServer.get_token "verboice", base_url, user_id
    Verboice.Client.new(base_url, oauth_token)
  end

  def sync_channels(user_id, base_url) do
    client = create_client(user_id, base_url)

    case client |> Verboice.Client.get_channels do
      {:ok, channel_names} ->
        sync_channels(user_id, base_url, channel_names)

      _ -> :error
    end
  end

  def sync_channels(user_id, base_url, channel_names) do
    user = Ask.User |> Repo.get!(user_id)
    channels = user |> assoc(:channels) |> where([c], c.provider == "verboice" and c.base_url == ^base_url) |> Repo.all

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
        |> Channel.changeset(%{name: name, type: "ivr", provider: "verboice", base_url: base_url, settings: %{"verboice_channel" => name}})
        |> Repo.insert
      end
    end)
  end

  defp channel_failed(respondent, status, %{"CallStatusReason" => reason, "CallStatusCode" => code}) do
    Broker.channel_failed(respondent, "#{status}: #{reason} (#{code})")
  end

  defp channel_failed(respondent, status, %{"CallStatusReason" => reason}) do
    Broker.channel_failed(respondent, "#{status}: #{reason}")
  end

  defp channel_failed(respondent, status, %{"CallStatusCode" => code}) do
    Broker.channel_failed(respondent, "#{status} (#{code})")
  end

  defp channel_failed(respondent, status, _) do
    Broker.channel_failed(respondent, status)
  end

  def callback(conn, %{"path" => ["status", respondent_id, _token], "CallStatus" => status} = params) do
    respondent = Repo.get!(Respondent, respondent_id)
    case status do
      s when s in ["failed", "busy", "no-answer"] ->
        channel_failed(respondent, status, params)
      _ -> :ok
    end

    conn |> send_resp(200, "")
  end

  def callback(conn, params) do
    callback(conn, params, Broker)
  end

  def callback(conn, params = %{"respondent" => respondent_id}, broker) do
    respondent = Respondent |> Repo.get(respondent_id)

    response_content = case respondent do
      nil ->
        hangup

      _ ->
        response = case params["Digits"] do
          nil -> Flow.Message.answer()
          "timeout" -> Flow.Message.no_reply
          digits -> Flow.Message.reply(digits)
        end

        case broker.sync_step(respondent, response, "ivr") do
          {:reply, reply} ->
            prompts = Reply.prompts(reply)
            gather(respondent, prompts)
          {:end, {:reply, reply}} ->
            prompts = Reply.prompts(reply)
            say_or_play(prompts) ++ [hangup]
          :end ->
            hangup
        end
    end

    reply = response(response_content) |> generate

    conn
    |> put_resp_content_type("text/xml")
    |> send_resp(200, reply)
  end

  def callback(conn, _, _) do
    conn
    |> put_resp_content_type("text/xml")
    |> send_resp(200, response(hangup) |> generate)
  end

  def callback_url(respondent) do
    Ask.Router.Helpers.callback_url(Ask.Endpoint, :callback, "verboice", respondent: respondent.id)
  end

  def no_reply_callback_url(respondent) do
    Ask.Router.Helpers.callback_url(Ask.Endpoint, :callback, "verboice", respondent: respondent.id, Digits: "timeout")
  end

  def status_callback_url(respondent, token) do
    respondent_id = respondent.id |> Integer.to_string
    Ask.Router.Helpers.callback_url(Ask.Endpoint, :callback, "verboice", ["status", respondent_id, token], [])
  end

  def process_call_response(response) do
    case response do
      {:ok, %{"call_id" => call_id}} ->
        {:ok, %{verboice_call_id: call_id}}
      _ ->
        {:error, response}
    end
  end

  defimpl Ask.Runtime.Channel, for: Ask.Runtime.VerboiceChannel do
    def has_delivery_confirmation?(_), do: false
    def ask(_, _, _, _), do: throw(:not_implemented)
    def prepare(_, _), do: :ok

    def setup(channel, respondent, token) do
      channel.client
      |> Verboice.Client.call(address: respondent.sanitized_phone_number,
                              channel: channel.channel_name,
                              callback_url: VerboiceChannel.callback_url(respondent),
                              status_callback_url: VerboiceChannel.status_callback_url(respondent, token))
      |> Ask.Runtime.VerboiceChannel.process_call_response
    end

    def has_queued_message?(channel, %{"verboice_call_id" => call_id}) do
      response = channel.client
      |> Verboice.Client.call_state(call_id)
      case response do
        {:ok, %{"state" => "completed"}} -> false
        {:ok, %{"state" => "failed"}} -> false
        {:ok, %{"state" => "canceled"}} -> false
        {:ok, %{"state" => _}} -> true
        _ -> false
      end
    end
    def has_queued_message?(_, _) do
      false
    end

    def cancel_message(channel, %{"verboice_call_id" => call_id}) do
      channel.client
      |> Verboice.Client.cancel(call_id)
    end
    def cancel_message(_, _) do
      :ok
    end
  end
end
