defmodule Ask.Runtime.VerboiceChannel do
  alias __MODULE__
  use Ask.Model
  alias Ask.{Repo, Respondent, Channel, SurvedaMetrics, Stats}

  alias Ask.Runtime.{
    Survey,
    Flow,
    Reply,
    RetriesHistogram,
    ChannelBroker
  }

  alias AskWeb.Router.Helpers
  import Plug.Conn
  import XmlBuilder
  @behaviour Ask.Runtime.ChannelProvider
  defstruct [:client, :channel_name, :channel_id]

  def new(channel) do
    channel_name = channel.settings["verboice_channel"]
    channel_id = channel.settings["verboice_channel_id"]
    client = create_client(channel.user_id, channel.base_url)
    %VerboiceChannel{client: client, channel_name: channel_name, channel_id: channel_id}
  end

  def oauth2_authorize(code, redirect_uri, base_url) do
    verboice_config = Ask.Config.provider_config(Verboice, base_url)
    guisso_config = verboice_config[:guisso]

    client =
      OAuth2.Client.new(
        client_id: guisso_config[:client_id],
        redirect_uri: redirect_uri,
        token_url: "#{guisso_config[:base_url]}/oauth2/token"
      )

    client =
      OAuth2.Client.get_token!(client,
        code: code,
        client_secret: guisso_config[:client_secret],
        token_type: "bearer"
      )

    client.token
  end

  def oauth2_refresh(access_token, base_url) do
    verboice_config = Ask.Config.provider_config(Verboice, base_url)
    guisso_config = verboice_config[:guisso]

    client =
      OAuth2.Client.new(
        token: access_token,
        client_id: guisso_config[:client_id],
        token_url: "#{guisso_config[:base_url]}/oauth2/token"
      )

    client =
      OAuth2.Client.refresh_token!(client,
        client_secret: guisso_config[:client_secret]
      )

    client.token
  end

  def gather(respondent, prompts = [prompt, _ | _], num_digits) do
    [
      say_or_play(prompt, channel_base_url(respondent))
      | gather(respondent, tl(prompts), num_digits)
    ]
  end

  def gather(respondent, prompts, num_digits) do
    channel_base_url = channel_base_url(respondent)

    gather_options =
      %{action: callback_url(respondent, channel_base_url), finishOnKey: ""}
      |> add_num_digits(num_digits)

    [
      # We need to set finishOnKey="" so that when a user presses '#'
      # the current question doesn't give a "timeout" from Verboice,
      # and '#' is sent here so it can be considered a refusal, a valid
      # option, etc.
      element(:Gather, gather_options, [
        say_or_play(prompts, channel_base_url)
      ]),
      element(:Redirect, no_reply_callback_url(respondent, channel_base_url))
    ]
  end

  defp respondent_channel(respondent) do
    try do
      session = respondent.session |> Ask.Runtime.Session.load()
      session.current_mode.channel
    rescue
      _ -> nil
    end
  end

  defp channel_base_url(respondent) do
    try do
      session = respondent.session |> Ask.Runtime.Session.load()
      channel = session.current_mode.channel
      channel.base_url
    rescue
      _ -> nil
    end
  end

  defp add_num_digits(options, num_digits) do
    if num_digits do
      Map.put(options, :numDigits, num_digits)
    else
      options
    end
  end

  def say_or_play(%{"audio_source" => audio_source, "audio_id" => audio_id}, channel_base_url)
      when audio_source in ["upload", "record"] do
    element(
      :Play,
      "#{
        verboice_callback(
          channel_base_url,
          Helpers.audio_delivery_path(AskWeb.Endpoint, :show, audio_id)
        )
      }.mp3"
    )
  end

  def say_or_play(%{"audio_source" => "tts", "text" => text}, _) do
    element(:Say, text)
  end

  def say_or_play(prompts, channel_base_url) do
    Enum.map(prompts, fn p -> say_or_play(p, channel_base_url) end)
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
    oauth_token = Ask.OAuthTokenServer.get_token("verboice", base_url, user_id)
    Verboice.Client.new(base_url, oauth_token)
  end

  def sync_channels(user_id, base_url) do
    client = create_client(user_id, base_url)

    case client |> Verboice.Client.get_channels() do
      {:ok, channel_names} ->
        sync_channels(user_id, base_url, channel_names)

      _ ->
        :error
    end
  end

  def sync_channels(user_id, base_url, api_channels) do
    user = Ask.User |> Repo.get!(user_id)

    channels =
      user
      |> assoc(:channels)
      |> where([c], c.provider == "verboice" and c.base_url == ^base_url)
      |> Repo.all()

    channels
    |> Enum.each(fn channel ->
      exists =
        api_channels
        |> Enum.any?(&match_channel(channel, &1))

      if !exists do
        Ask.Channel.delete(channel)
      end
    end)

    api_channels
    |> Enum.each(fn api_channel ->
      channel =
        channels
        |> Enum.find(&match_channel(&1, api_channel))

      channel =
        if channel do
          channel
        else
          user
          |> Ecto.build_assoc(:channels)
        end

      channel
      |> channel_changeset(base_url, api_channel)
      |> Repo.insert_or_update!()
    end)
  end

  def create_channel(user, base_url, api_channel) do
    user
    |> Ecto.build_assoc(:channels)
    |> channel_changeset(base_url, api_channel)
    |> Repo.insert!()
  end

  defp channel_changeset(channel, base_url, api_channel) do
    settings = %{
      "verboice_channel" => api_channel["name"],
      "verboice_channel_id" => api_channel["id"]
    }

    settings =
      if api_channel["shared_by"] do
        settings |> Map.put("shared_by", api_channel["shared_by"])
      else
        settings
      end

    Channel.changeset(channel, %{
      name: api_channel["name"],
      type: "ivr",
      provider: "verboice",
      base_url: base_url,
      settings: settings
    })
  end

  defp match_channel(%{settings: %{"verboice_channel_id" => id}}, %{"id" => id}), do: true
  defp match_channel(%{settings: %{"verboice_channel" => name}}, %{"name" => name}), do: true
  defp match_channel(_, _), do: false

  defp channel_failed(respondent, "failed", %{
         "CallStatusReason" => "Busy",
         "CallStatusCode" => code
       }) do
    Survey.channel_failed(respondent, "User hangup (#{code})")
  end

  defp channel_failed(respondent, "failed", %{
         "CallStatusReason" => reason,
         "CallStatusCode" => code
       }) do
    Survey.channel_failed(respondent, "#{reason} (#{code})")
  end

  defp channel_failed(respondent, status, %{
         "CallStatusReason" => reason,
         "CallStatusCode" => code
       }) do
    Survey.channel_failed(respondent, "#{status}: #{reason} (#{code})")
  end

  defp channel_failed(respondent, "failed", %{"CallStatusReason" => "Busy"}) do
    Survey.channel_failed(respondent, "User hangup")
  end

  defp channel_failed(respondent, "failed", %{"CallStatusReason" => reason}) do
    Survey.channel_failed(respondent, "#{reason}")
  end

  defp channel_failed(respondent, status, %{"CallStatusReason" => reason}) do
    Survey.channel_failed(respondent, "#{status}: #{reason}")
  end

  defp channel_failed(respondent, "failed", %{"CallStatusCode" => code}) do
    Survey.channel_failed(respondent, "(#{code})")
  end

  defp channel_failed(respondent, status, %{"CallStatusCode" => code}) do
    Survey.channel_failed(respondent, "#{status} (#{code})")
  end

  defp channel_failed(respondent, status, _) do
    Survey.channel_failed(respondent, status)
  end

  defp update_call_time_seconds(respondent, call_sid, call_time) do
    stats =
      respondent.stats
      |> Stats.with_call_time(call_sid, call_time)

    respondent
    |> Respondent.changeset(%{stats: stats})
    |> Repo.update!()
  end

  def callback(
        conn,
        %{
          "path" => ["status", respondent_id, _token],
          "CallStatus" => status,
          "CallDuration" => call_duration_seconds,
          "CallSid" => call_sid
        } = params
      ) do
    call_duration = call_duration_seconds |> String.to_integer()

    Respondent.with_lock(respondent_id, fn respondent ->
      case respondent do
        # Ignore the callback if the respondent doesn't exist
        nil ->
          :ok

        respondent ->
          respondent = update_call_time_seconds(respondent, call_sid, call_duration)
          channel = respondent_channel(respondent)
          # The respondent has a current_mode, then provider should not be necessary
          ChannelBroker.callback_received(
            channel.id,
            respondent,
            status,
            "verboice"
          )

          case status do
            "expired" ->
              # respondent is still being considered as active in Surveda
              Survey.contact_attempt_expired(respondent)

            s when s in ["failed", "busy", "no-answer"] ->
              # respondent should no longer be considered as active
              respondent =
                RetriesHistogram.respondent_no_longer_active(respondent)
                |> Respondent.call_attempted()

              channel_failed(respondent, status, params)

            _ ->
              Respondent.call_attempted(respondent)
          end
      end
    end)

    SurvedaMetrics.increment_counter_with_label(:surveda_verboice_status_callback, [status])
    conn |> send_resp(200, "")
  end

  def callback(conn, params) do
    callback(conn, params, Survey)
  end

  def callback(conn, params = %{"respondent" => respondent_id}, survey) do
    response_content =
      Respondent.with_lock(respondent_id, fn respondent ->
        case respondent do
          nil ->
            hangup()

          %Respondent{session: %{"current_mode" => %{"mode" => "ivr"}}} ->
            respondent = Respondent.call_attempted(respondent)

            response =
              case params["Digits"] do
                nil -> Flow.Message.answer()
                "timeout" -> Flow.Message.no_reply()
                digits -> Flow.Message.reply(digits)
              end

            case survey.sync_step(respondent, response, "ivr") do
              {:reply, reply, _} ->
                prompts = Reply.prompts(reply)
                num_digits = Reply.num_digits(reply)
                gather(respondent, prompts, num_digits)

              {:end, {:reply, reply}, _} ->
                prompts = Reply.prompts(reply)
                say_or_play(prompts, channel_base_url(respondent)) ++ [hangup()]

              {:end, _} ->
                hangup()
            end

          _ ->
            hangup()
        end
      end)

    reply = response(response_content) |> generate

    conn
    |> put_resp_content_type("text/xml")
    |> send_resp(200, reply)
  end

  def callback(conn, _, _) do
    conn
    |> put_resp_content_type("text/xml")
    |> send_resp(200, response(hangup()) |> generate)
  end

  def callback_url(respondent, channel_base_url) do
    verboice_callback(
      channel_base_url,
      AskWeb.Router.Helpers.callback_path(AskWeb.Endpoint, :callback, "verboice",
        respondent: respondent.id
      )
    )
  end

  def no_reply_callback_url(respondent, channel_base_url) do
    verboice_callback(
      channel_base_url,
      AskWeb.Router.Helpers.callback_path(AskWeb.Endpoint, :callback, "verboice",
        respondent: respondent.id,
        Digits: "timeout"
      )
    )
  end

  def status_callback_url(respondent, channel_base_url, token) do
    respondent_id = respondent.id |> Integer.to_string()

    verboice_callback(
      channel_base_url,
      AskWeb.Router.Helpers.callback_path(
        AskWeb.Endpoint,
        :callback,
        "verboice",
        ["status", respondent_id, token],
        []
      )
    )
  end

  defp verboice_callback(channel_base_url, path) do
    Ask.Runtime.ChannelHelper.provider_callback_url(Verboice, channel_base_url, path)
  end

  def process_call_response(response) do
    case response do
      {:ok, %{"call_id" => call_id}} ->
        {:ok, %{verboice_call_id: call_id}}

      _ ->
        {:error, response}
    end
  end

  def check_status(%{
        "status" => %{
          "ok" => false,
          "messages" => messages
        }
      }),
      do: {:down, messages}

  def check_status(%{"enabled" => false}), do: {:down, ["Channel is disabled"]}

  def check_status(_), do: :up

  defimpl Ask.Runtime.Channel, for: Ask.Runtime.VerboiceChannel do
    def has_delivery_confirmation?(_), do: false
    def ask(_, _, _, _, _), do: throw(:not_implemented)
    def prepare(_), do: :ok

    def setup(channel, respondent, token, not_before, not_after) do
      in_five_seconds = Timex.shift(not_before, seconds: 5)
      channel_base_url = channel.client.base_url

      params = [
        address: respondent.sanitized_phone_number,
        callback_url: VerboiceChannel.callback_url(respondent, channel_base_url),
        status_callback_url:
          VerboiceChannel.status_callback_url(respondent, channel_base_url, token),
        not_before: in_five_seconds,
        not_after: not_after
      ]

      params =
        if channel.channel_id do
          Keyword.put(params, :channel_id, channel.channel_id)
        else
          Keyword.put(params, :channel, channel.channel_name)
        end

      channel.client
      |> Verboice.Client.call(params)
      |> VerboiceChannel.process_call_response()
    end

    def has_queued_message?(channel, %{"verboice_call_id" => call_id}) do
      response =
        channel.client
        |> Verboice.Client.call_state(call_id)

      case response do
        {:ok, %{"state" => "completed"}} -> false
        {:ok, %{"state" => "failed"}} -> false
        {:ok, %{"state" => "canceled"}} -> false
        {:ok, %{"state" => "expired"}} -> false
        {:ok, %{"state" => _}} -> true
        _ -> false
      end
    end

    def has_queued_message?(_, _) do
      false
    end

    def message_expired?(channel, %{"verboice_call_id" => call_id}) do
      response =
        channel.client
        |> Verboice.Client.call_state(call_id)

      case response do
        {:ok, %{"state" => "expired"}} -> true
        _ -> false
      end
    end

    def message_expired?(_, _) do
      false
    end

    def cancel_message(channel, %{"verboice_call_id" => call_id}) do
      channel.client
      |> Verboice.Client.cancel(call_id)
    end

    def cancel_message(_, _) do
      :ok
    end

    def check_status(channel) do
      case channel.client |> Verboice.Client.get_channel(channel.channel_id) do
        {:ok, channel} -> VerboiceChannel.check_status(channel)
        error -> error
      end
    end
  end
end
