defmodule Ask.Runtime.NuntiumChannel do
  @behaviour Ask.Runtime.ChannelProvider
  use Ask.Web, :model
  alias Ask.Runtime.{Broker, NuntiumChannel, Flow, Reply}
  alias Ask.{Repo, Respondent, Channel}
  import Ecto.Query
  import Plug.Conn
  defstruct [:oauth_token, :name, :settings]

  def new(channel) do
    oauth_token = Ask.OAuthTokenServer.get_token "nuntium", channel.user_id
    name = channel.name
    %NuntiumChannel{oauth_token: oauth_token, name: name, settings: channel.settings}
  end

  def oauth2_authorize(code, redirect_uri, _callback_url) do
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

  def callback(conn, args = %{"path" => ["status"], "respondent_id" => respondent_id, "session_token" => token, "state" => state}) do
    respondent = Repo.get!(Respondent, respondent_id)
    case state do
      "failed" ->
        Broker.channel_failed(respondent, token)
      "delivered" ->
        Broker.delivery_confirm(respondent, token, args["step_title"], args["respondent_disposition"])
    end

    conn |> send_resp(200, "")
  end

  def callback(conn, %{"from" => from, "body" => body}) do
    %URI{host: phone_number} = URI.parse(from)

    respondent = Repo.one(from r in Respondent,
      where: r.sanitized_phone_number == ^phone_number and (r.state == "active" or r.state == "stalled"),
      order_by: [desc: r.updated_at],
      limit: 1)

    reply = case respondent do
      nil ->
        nil
      _ ->
        case Broker.sync_step(respondent, Flow.Message.reply(body)) do
          {:reply, reply} ->
            reply
          {:end, {:reply, reply}} ->
            reply
          :end ->
            nil
        end
    end

    json_reply = reply_to_messages(reply, from, respondent)
    Phoenix.Controller.json(conn, json_reply)
  end

  def callback(conn, _) do
    conn |> send_resp(404, "not found")
  end

  def reply_to_messages(nil, _to, _respondent) do; []; end

  def reply_to_messages(_reply, _to, nil) do; []; end

  def reply_to_messages(reply, to, respondent) do
    Enum.flat_map Reply.steps(reply), fn step ->
      step[:prompts] |> Enum.with_index |> Enum.map(fn {prompt, index} ->
        %{
          to: to,
          body: prompt,
          respondent_id: respondent.id,
          respondent_disposition: Reply.disposition(reply),
          step_title: Reply.step_title_with_index(step, index)
        }
      end)
    end
  end

  def sync_channels(user_id) do
    nuntium_config = Application.get_env(:ask, Nuntium)
    oauth_token = Ask.OAuthTokenServer.get_token "nuntium", user_id
    client = Nuntium.Client.new(nuntium_config[:base_url], oauth_token)

    case client |> Nuntium.Client.get_accounts do
      {:ok, accounts} ->
        case collect_remote_channels(client, accounts) do
          {:ok, channels} ->
            sync_channels(user_id, channels)

          error -> error
        end

      error -> error
    end
  end

  defp collect_remote_channels(client, accounts, all_channels \\ []) do
    case accounts do
      [account | accounts] ->
        case client |> Nuntium.Client.get_channels(account) do
          {:ok, channels} ->
            new_channels = Enum.map(channels, fn ch -> {account, ch} end)
            collect_remote_channels(client, accounts, all_channels ++ new_channels)

          error -> error
        end

      [] -> {:ok, all_channels}
    end
  end

  defp sync_channels(user_id, nuntium_channels) do
    user = Ask.User |> Repo.get!(user_id)
    channels = user |> assoc(:channels) |> where([c], c.provider == "nuntium") |> Repo.all

    channels |> Enum.each(fn channel ->
      exists = nuntium_channels |> Enum.any?(fn {account, nuntium_channel} -> same_channel?(channel, account, nuntium_channel) end)
      if !exists do
        channel |> Repo.delete
      end
    end)

    nuntium_channels |> Enum.each(fn {account, nuntium_channel} ->
      exists = channels |> Enum.any?(&same_channel?(&1, account, nuntium_channel))
      if !exists do
        user
        |> Ecto.build_assoc(:channels)
        |> Channel.changeset(%{name: "#{nuntium_channel["name"]} - #{account}", type: "sms", provider: "nuntium", settings: %{
            "nuntium_channel" => nuntium_channel["name"],
            "nuntium_account" => account
          }})
        |> Repo.insert
      end
    end)

    :ok
  end

  defp same_channel?(channel, account, nuntium_channel) do
    channel.settings["nuntium_account"] == account &&
    channel.settings["nuntium_channel"] == nuntium_channel["name"]
  end

  defimpl Ask.Runtime.Channel, for: Ask.Runtime.NuntiumChannel do
    def prepare(channel, callback_url) do
      # Update the Nuntium app to setup the callback URL
      nuntium_config = Application.get_env(:ask, Nuntium)
      client = Nuntium.Client.new(nuntium_config[:base_url], channel.oauth_token)

      app_settings = %{
        interface: %{
          type: "http_get_callback",
          url: callback_url
        },
        delivery_ack: %{
          method: "get",
          url: Ask.Router.Helpers.callback_url(Ask.Endpoint, :callback, "nuntium", ["status"], [])
        }
      }

      case client |> Nuntium.Client.application_update(channel.settings["nuntium_account"], app_settings) do
        {:ok, %{"name" => app_name}} ->

          case Nuntium.Client.channel_update(client,
            channel.settings["nuntium_account"],
            channel.settings["nuntium_channel"],
            %{application: app_name, enabled: true}) do

            {:ok, _} -> :ok

            error -> error
          end

        error -> error
      end
    end

    def setup(_channel, _respondent, _token), do: :ok
    def can_push_question?(_), do: true

    def ask(channel, respondent, token, reply) do
      nuntium_config = Application.get_env(:ask, Nuntium)
      to = "sms://#{respondent.sanitized_phone_number}"
      messages = Ask.Runtime.NuntiumChannel.reply_to_messages(reply, to, respondent) |>
        Enum.map(fn(msg) ->
          Map.merge(msg, %{suggested_channel: channel.settings["nuntium_channel"], session_token: token})
        end)

      Nuntium.Client.new(nuntium_config[:base_url], channel.oauth_token)
      |> Nuntium.Client.send_ao(channel.settings["nuntium_account"], messages)
    end

    def has_delivery_confirmation?(_), do: true
    def has_queued_message?(_, _), do: false
    def cancel_message(_, _), do: :ok
  end
end
