defprotocol Ask.Runtime.Channel do
  def prepare(channel, callback_url)
  def setup(channel, respondent, token)
  def can_push_question?(channel)
  def ask(channel, respondent, token, prompts)
  def has_queued_message?(channel, channel_state)
  def cancel_message(channel, channel_state)
end

defmodule Ask.Runtime.ChannelProvider do
  @callback new(channel :: Ask.Channel) :: Ask.Runtime.Channel
  @callback oauth2_authorize(code :: String.t, redirect_uri :: String.t, callback_url :: String.t) :: OAuth2.AccessToken.t
  @callback oauth2_refresh(access_token :: OAuth2.AccessToken.t) :: OAuth2.AccessToken.t
  @callback sync_channels(user_id :: integer) :: :ok
  @callback callback(conn :: Plug.Conn.t, params :: map()) :: Plug.Conn.t
end
