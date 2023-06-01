defprotocol Ask.Runtime.Channel do
  # TODO: finish reverse-engineering the typespec definitions

  @type t :: map()

  # Returns whether the channel sends delivery confirmations callbacks or not.
  @spec has_delivery_confirmation?(t()) :: boolean
  def has_delivery_confirmation?(channel)

  # Configure the channel to start communicating with Surveda. For example setup
  # the callback URL on the remote service.
  @spec prepare(t()) :: any()
  def prepare(channel)

  # Queue a long running session. The survey will be responded when the remote
  # channel callbacks into Surveda.
  @spec setup(t(), Ask.Respondent.t(), any(), any(), any()) :: any()
  def setup(channel, respondent, token, not_before, not_after)

  # Queue one message or set of messages to be sent. The Survey shall be run one
  # reply at a time.
  @spec ask(t(), Ask.Respondent.t(), any(), any(), integer()) :: any()
  def ask(channel, respondent, token, prompts, channel_id)

  # Returns how many contacts will be queued on the remote channel.
  @spec messages_count(t(), Ask.Respondent.t(), any(), [Ask.Runtime.Reply.t()], integer()) :: integer()
  def messages_count(channel, respondent, to, reply, channel_id)

  # Verify if a message has already been queued. `channel_state` will contain
  @spec has_queued_message?(t(), map()) :: boolean
  def has_queued_message?(channel, channel_state)

  # Verify if the given message is still in an active state (e.g. queued or
  # activate) or inactive (e.g. completed, failed).
  @spec message_inactive?(t(), map()) :: boolean
  def message_inactive?(channel, channel_state)

  # Cancel a previously sent message.
  @spec cancel_message(t(), map()) :: boolean
  def cancel_message(channel, channel_state)

  # Verify if a previously queued message has expired.
  @spec message_expired?(t(), map()) :: boolean
  def message_expired?(channel, channel_state)

  # Returns the status of the channel.
  #
  # `:up | {:down, messages} | {:error, messages}`
  @spec(check_status(t()) :: :up | {:down, []}, {:error, []})
  def check_status(channel)
end

defmodule Ask.Runtime.ChannelProvider do
  @callback new(channel :: Ask.Channel) :: Ask.Runtime.Channel
  @callback oauth2_authorize(
              code :: String.t(),
              redirect_uri :: String.t(),
              base_url :: String.t()
            ) :: OAuth2.AccessToken.t()
  @callback oauth2_refresh(access_token :: OAuth2.AccessToken.t(), base_url :: String.t()) ::
              OAuth2.AccessToken.t()
  @callback sync_channels(user_id :: integer, base_url :: String.t()) :: :ok
  @callback create_channel(user :: Ask.User.t(), base_url :: String.t(), api_channel :: map) ::
              Ask.Channel
  @callback callback(conn :: Plug.Conn.t(), params :: map()) :: Plug.Conn.t()
end

defmodule Ask.Runtime.ChannelHelper do
  def provider_callback_url(_provider, nil, path), do: application_endpoint() <> path

  def provider_callback_url(provider, channel_base_url, path),
    do: provider_callback_endpoint(provider, channel_base_url) <> path

  defp provider_callback_endpoint(provider, channel_base_url) do
    case Ask.Config.provider_config(provider, channel_base_url) do
      nil -> application_endpoint()
      config -> config[:base_callback_url] || application_endpoint()
    end
  end

  def application_endpoint(), do: AskWeb.Endpoint.url()
end
