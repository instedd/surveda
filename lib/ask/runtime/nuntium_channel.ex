defmodule Ask.Runtime.NuntiumChannel do
  @behaviour Ask.Runtime.ChannelProvider
  use Ask.Model
  alias Ask.Runtime.{Survey, NuntiumChannel, Flow, Reply, ReplyStep, ChannelBroker}
  alias Ask.{Repo, Respondent, Channel, SurvedaMetrics, Logger}
  import Ecto.Query
  import Plug.Conn
  defstruct [:oauth_token, :name, :base_url, :settings]

  def new(channel) do
    oauth_token = Ask.OAuthTokenServer.get_token("nuntium", channel.base_url, channel.user_id)

    %NuntiumChannel{
      oauth_token: oauth_token,
      name: channel.name,
      base_url: channel.base_url,
      settings: channel.settings
    }
  end

  def oauth2_authorize(code, redirect_uri, base_url) do
    nuntium_config = Ask.Config.provider_config(Nuntium, base_url)
    guisso_config = nuntium_config[:guisso]

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
    nuntium_config = Ask.Config.provider_config(Nuntium, base_url)
    guisso_config = nuntium_config[:guisso]

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

  defp respondent_channel(respondent) do
    try do
      session = respondent.session |> Ask.Runtime.Session.load()
      session.current_mode.channel
    rescue
      _ -> nil
    end
  end

  def callback(conn, params) do
    callback(conn, params, Survey)
  end

  @doc """
  Endpoint that handles the AO message status updates from Nuntium
  This callback will be invoked when an AO message's state changes to either 'failed', 'delivered' or 'confirmed'.
  https://app.surveda.lvh.me//callbacks/nuntium
  """
  def callback(
        conn,
        %{"path" => ["status"], "respondent_id" => respondent_id, "state" => state} = args,
        survey
      ) do
    Respondent.with_lock(respondent_id, fn respondent ->
      case respondent do
        nil ->
          # Ignore the callback if the respondent doesn't exist, otherwise Nuntium will retry forever
          :ok

        respondent ->
          channel_id = args["channel_id"]

          case channel_id do
            nil ->
              # For backward compatibility only
              # From the moment the ChannelBroker go live to production, every AO message will
              # include the channel_id. Only older messages should reach this chunk of code.
              Logger.warn(
                "Nuntium: missing channel_id in AO callback respondent_id=#{respondent_id}"
              )

              nil

            _ ->
              # Ideally, we'd forward the confirmed status, but there is no
              # guarantee that an external provider will confirm AO messages. We
              # also can't react to both as the channel broker would decrement
              # the number of active messages twice. The cancelled state isn't
              # currenlty sent by Nuntium, but maybe that will change in the
              # future.
              if state in ["failed", "delivered", "cancelled"] do
                ChannelBroker.callback_received(channel_id, respondent, state, "nuntium")
              end
          end

          case state do
            "failed" ->
              survey.channel_failed(respondent)

            "delivered" ->
              survey.delivery_confirm(respondent, args["step_title"], "sms")

            _ ->
              :ok
          end
      end

      SurvedaMetrics.increment_counter_with_label(:surveda_nuntium_status_callback, [state])
    end)

    conn |> send_resp(200, "")
  end

  @doc """
  Endpoint that handles the AT messages received from Nuntium
  """
  def callback(conn, %{"from" => from, "body" => body}, survey) do
    %URI{host: phone_number} = URI.parse(from)

    respondent_id =
      Repo.one(
        from r in Respondent,
          select: r.id,
          where: r.sanitized_phone_number == ^phone_number and r.state == :active,
          order_by: [desc: r.updated_at],
          limit: 1
      )

    {reply, channel_id} =
      case respondent_id do
        nil ->
          {nil, nil}

        _ ->
          Respondent.with_lock(respondent_id, fn respondent ->
            case respondent do
              %Respondent{session: %{"current_mode" => %{"mode" => "sms"}}} ->
                channel = respondent_channel(respondent)

                case channel do
                  nil ->
                    # If there's a living session, it should have a channel
                    Logger.error(
                      "Nuntium: missing channel_id in AT callback respondent_id=#{respondent_id}"
                    )

                    {nil, nil}

                  _ ->
                    case survey.sync_step(respondent, Flow.Message.reply(body), "sms") do
                      {:reply, reply, respondent} ->
                        update_stats(respondent.id, reply)
                        {reply, channel.id}

                      {:end, {:reply, reply}, respondent} ->
                        update_stats(respondent.id, reply)
                        {reply, channel.id}

                      {:end, respondent} ->
                        update_stats(respondent.id)
                        {nil, nil}
                    end
                end

              _ ->
                {nil, nil}
            end
          end)
      end

    json_reply = reply_to_messages(reply, from, respondent_id, channel_id)

    case json_reply do
      [] ->
        :ok

      _ ->
        ChannelBroker.force_activate_respondent(channel_id, respondent_id, length(json_reply))
    end

    SurvedaMetrics.increment_counter(:surveda_nuntium_incoming)
    Phoenix.Controller.json(conn, json_reply)
  end

  def callback(conn, _, _) do
    # Ignore other callbacks, otherwise Nuntium will retry forever
    conn |> send_resp(200, "OK")
  end

  def reply_to_messages(nil, _to, _respondent_id, _channel_id) do
    []
  end

  def reply_to_messages(_reply, _to, nil, _channel_id) do
    []
  end

  def reply_to_messages(_reply, _to, _respondent_id, nil) do
    []
  end

  def reply_to_messages(reply, to, respondent_id, channel_id) do
    Enum.flat_map(Reply.steps(reply), fn step ->
      step.prompts
      |> Enum.with_index()
      |> Enum.map(fn {prompt, index} ->
        %{
          to: to,
          body: prompt,
          respondent_id: respondent_id,
          step_title: ReplyStep.title_with_index(step, index + 1),
          channel_id: channel_id
        }
      end)
    end)
  end

  def update_stats(respondent, reply \\ %Reply{}) do
    Respondent.update_stats(respondent, reply, true)
  end

  def sync_channels(user_id, base_url) do
    oauth_token = Ask.OAuthTokenServer.get_token("nuntium", base_url, user_id)
    client = Nuntium.Client.new(base_url, oauth_token)

    case client |> Nuntium.Client.get_accounts() do
      {:ok, accounts} ->
        case collect_remote_channels(client, accounts) do
          {:ok, channels} ->
            sync_channels(user_id, base_url, channels)

          error ->
            error
        end

      error ->
        error
    end
  end

  def create_channel(user, base_url, api_channel) do
    user
    |> Ecto.build_assoc(:channels)
    |> channel_changeset(base_url, api_channel)
    |> Repo.insert!()
  end

  defp channel_changeset(channel, base_url, api_channel) do
    settings = %{
      "nuntium_account" => api_channel["account"],
      "nuntium_channel" => api_channel["name"]
    }

    Channel.changeset(channel, %{
      name: "#{api_channel["name"]} - #{api_channel["account"]}",
      type: "sms",
      provider: "nuntium",
      base_url: base_url,
      settings: settings
    })
  end

  defp collect_remote_channels(client, accounts, all_channels \\ []) do
    case accounts do
      [account | accounts] ->
        case client |> Nuntium.Client.get_channels(account) do
          {:ok, channels} ->
            new_channels = Enum.map(channels, fn ch -> {account, ch} end)
            collect_remote_channels(client, accounts, all_channels ++ new_channels)

          error ->
            error
        end

      [] ->
        {:ok, all_channels}
    end
  end

  def sync_channels(user_id, base_url, nuntium_channels) do
    user = Ask.User |> Repo.get!(user_id)

    channels =
      user
      |> assoc(:channels)
      |> where([c], c.provider == "nuntium" and c.base_url == ^base_url)
      |> Repo.all()

    channels
    |> Enum.each(fn channel ->
      exists =
        nuntium_channels
        |> Enum.any?(fn {account, nuntium_channel} ->
          same_channel?(channel, account, nuntium_channel)
        end)

      if !exists do
        Ask.Channel.delete(channel)
      end
    end)

    nuntium_channels
    |> Enum.each(fn {account, nuntium_channel} ->
      exists = channels |> Enum.any?(&same_channel?(&1, account, nuntium_channel))

      if !exists do
        user
        |> Ecto.build_assoc(:channels)
        |> Channel.changeset(%{
          name: "#{nuntium_channel["name"]} - #{account}",
          type: "sms",
          provider: "nuntium",
          base_url: base_url,
          settings: %{
            "nuntium_channel" => nuntium_channel["name"],
            "nuntium_account" => account
          }
        })
        |> Repo.insert()
      end
    end)

    :ok
  end

  defp same_channel?(channel, account, nuntium_channel) do
    channel.settings["nuntium_account"] == account &&
      channel.settings["nuntium_channel"] == nuntium_channel["name"]
  end

  def check_status(%{"enabled" => enabled, "connected" => connected}) do
    if enabled && connected do
      :up
    else
      {:down, []}
    end
  end

  def check_status(%{"enabled" => true}), do: :up
  def check_status(_any_other), do: {:down, []}

  def nuntium_callback(channel, path),
    do: Ask.Runtime.ChannelHelper.provider_callback_url(Nuntium, channel.base_url, path)

  defimpl Ask.Runtime.Channel, for: Ask.Runtime.NuntiumChannel do
    def prepare(channel) do
      callback_url =
        NuntiumChannel.nuntium_callback(
          channel,
          AskWeb.Router.Helpers.callback_path(AskWeb.Endpoint, :callback, "nuntium")
        )

      # Update the Nuntium app to setup the callback URL
      client = Nuntium.Client.new(channel.base_url, channel.oauth_token)

      app_settings = %{
        interface: %{
          type: "http_get_callback",
          url: callback_url
        },
        delivery_ack: %{
          method: "get",
          url:
            NuntiumChannel.nuntium_callback(
              channel,
              AskWeb.Router.Helpers.callback_path(
                AskWeb.Endpoint,
                :callback,
                "nuntium",
                ["status"],
                []
              )
            )
        }
      }

      case client
           |> Nuntium.Client.application_update(channel.settings["nuntium_account"], app_settings) do
        {:ok, %{"name" => app_name}} ->
          case Nuntium.Client.channel_update(
                 client,
                 channel.settings["nuntium_account"],
                 channel.settings["nuntium_channel"],
                 %{application: app_name, enabled: true}
               ) do
            {:ok, _} -> :ok
            error -> error
          end

        error ->
          error
      end
    end

    def setup(_channel, _respondent, _token, _not_before, _not_after), do: {:ok, %{}}

    def ask(channel, respondent, token, reply, channel_id) do
      to = "sms://#{respondent.sanitized_phone_number}"

      messages =
        reply
        |> NuntiumChannel.reply_to_messages(to, respondent.id, channel_id)
        |> Enum.map(fn msg ->
          Map.merge(msg, %{
            suggested_channel: channel.settings["nuntium_channel"],
            channel: channel.settings["nuntium_channel"],
            session_token: token
          })
        end)

      Nuntium.Client.new(channel.base_url, channel.oauth_token)
      |> Nuntium.Client.send_ao(channel.settings["nuntium_account"], messages)
    end

    # OPTIMIZE: count messages, don't generate 'em just to count the result
    def messages_count(_, respondent, to, reply, channel_id) do
      reply
      |> NuntiumChannel.reply_to_messages(to, respondent.id, channel_id)
      |> length()
    end

    def check_status(runtime_channel) do
      client = Nuntium.Client.new(runtime_channel.base_url, runtime_channel.oauth_token)

      case client
           |> Nuntium.Client.get_channel(
             runtime_channel.settings["nuntium_account"],
             runtime_channel.settings["nuntium_channel"]
           ) do
        {:ok, channel} -> NuntiumChannel.check_status(channel)
        error -> error
      end
    end

    def message_inactive?(runtime_channel, %{"nuntium_token" => nuntium_token}) do
      client = Nuntium.Client.new(runtime_channel.base_url, runtime_channel.oauth_token)
      account = runtime_channel.settings["nuntium_account"]
      inactive_states = ["delivered", "confirmed", "failed", "cancelled"]

      case Nuntium.Client.get_ao(client, account, nuntium_token) do
        {:ok, ao_messages} ->
          Enum.all?(ao_messages, fn m -> m["state"] in inactive_states end)

        {:error, _} ->
          # in case of error, we consider it's still active
          false
      end
    end

    def has_delivery_confirmation?(_), do: true
    def has_queued_message?(_, _), do: false
    def message_expired?(_, _), do: false
    def cancel_message(_, _), do: :ok
  end
end
