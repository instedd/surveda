defprotocol Ask.Runtime.Channel do
  def prepare(channel, callback_url)
  def setup(channel, respondent, token, not_before, not_after)
  def has_delivery_confirmation?(channel)
  def ask(channel, respondent, token, prompts)
  def has_queued_message?(channel, channel_state)
  def cancel_message(channel, channel_state)
  def message_expired?(channel, channel_state)
  def check_status(channel) # :up | {:down, message} | {:error, message}
end

defmodule Ask.Runtime.ChannelProvider do
  @callback new(channel :: Ask.Channel) :: Ask.Runtime.Channel
  @callback oauth2_authorize(code :: String.t, redirect_uri :: String.t, base_url :: String.t) :: OAuth2.AccessToken.t
  @callback oauth2_refresh(access_token :: OAuth2.AccessToken.t, base_url :: String.t) :: OAuth2.AccessToken.t
  @callback sync_channels(user_id :: integer, base_url :: String.t) :: :ok
  @callback create_channel(user :: Ask.User.t, base_url :: String.t, api_channel :: map) :: Ask.Channel
  @callback callback(conn :: Plug.Conn.t, params :: map()) :: Plug.Conn.t
end
