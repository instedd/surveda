defmodule Ask.Runtime.NuntiumChannel do
  @behaviour Ask.Runtime.ChannelProvider
  use Ask.Model
  alias Ask.Runtime.{Survey, NuntiumChannel, Flow, Reply, ReplyStep, ChannelBrokerSupervisor}
  alias Ask.{Repo, Respondent, Channel, Stats, SurvedaMetrics}
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

  def callback(conn, params) do
    callback(conn, params, Survey)
  end

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

    reply =
      case respondent_id do
        nil ->
          nil

        _ ->
          Respondent.with_lock(respondent_id, fn respondent ->
            case respondent do
              %Respondent{session: %{"current_mode" => %{"mode" => "sms"}}} ->
                case survey.sync_step(respondent, Flow.Message.reply(body), "sms") do
                  {:reply, reply, respondent} ->
                    update_stats(respondent, reply)
                    reply

                  {:end, {:reply, reply}, respondent} ->
                    update_stats(respondent, reply)
                    reply

                  {:end, respondent} ->
                    update_stats(respondent)
                    nil
                end

              _ ->
                nil
            end
          end)
      end

    json_reply = reply_to_messages(reply, from, respondent_id)
    SurvedaMetrics.increment_counter(:surveda_nuntium_incoming)
    Phoenix.Controller.json(conn, json_reply)
  end

  def callback(conn, _, _) do
    # Ignore other callbacks, otherwise Nuntium will retry forever
    conn |> send_resp(200, "OK")
  end

  def reply_to_messages(nil, _to, _respondent_id) do
    []
  end

  def reply_to_messages(_reply, _to, nil) do
    []
  end

  def reply_to_messages(reply, to, respondent_id) do
    Enum.flat_map(Reply.steps(reply), fn step ->
      step.prompts
      |> Enum.with_index()
      |> Enum.map(fn {prompt, index} ->
        %{
          to: to,
          body: prompt,
          respondent_id: respondent_id,
          step_title: ReplyStep.title_with_index(step, index + 1)
        }
      end)
    end)
  end

  def update_stats(respondent, reply \\ %Reply{}) do
    respondent = Repo.get(Respondent, respondent.id)
    stats = respondent.stats

    stats =
      stats
      |> Stats.add_received_sms()
      |> Stats.add_sent_sms(Enum.count(Reply.prompts(reply)))

    respondent
    |> Respondent.changeset(%{stats: stats})
    |> Repo.update!()
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
    channel = user
    |> Ecto.build_assoc(:channels)
    |> channel_changeset(base_url, api_channel)
    |> Repo.insert!()

    {:ok, _pid} = ChannelBrokerSupervisor.start_child(channel.id, channel.settings)

    channel
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
        {:ok, %Channel{id: channel_id, settings: settings}} = user
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

        {:ok, _pid} = ChannelBrokerSupervisor.start_child(channel_id, settings)
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

    def setup(_channel, _respondent, _token, _not_before, _not_after), do: :ok

    def ask(channel, respondent, token, reply) do
      to = "sms://#{respondent.sanitized_phone_number}"

      messages =
        NuntiumChannel.reply_to_messages(reply, to, respondent.id)
        |> Enum.map(fn msg ->
          Map.merge(msg, %{
            suggested_channel: channel.settings["nuntium_channel"],
            channel: channel.settings["nuntium_channel"],
            session_token: token
          })
        end)

      respondent = NuntiumChannel.update_stats(respondent)

      Nuntium.Client.new(channel.base_url, channel.oauth_token)
      |> Nuntium.Client.send_ao(channel.settings["nuntium_account"], messages)

      respondent
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

    def has_delivery_confirmation?(_), do: true
    def has_queued_message?(_, _), do: false
    def message_expired?(_, _), do: false
    def cancel_message(_, _), do: :ok
  end
end
