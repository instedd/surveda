defprotocol Ask.Runtime.Channel do
  def ask(channel, phone_number, prompts)
end

defmodule Ask.Runtime.ChannelProvider do
  @callback new(map()) :: Ask.Runtime.Channel
  @callback oauth2_authorize(String.t, String.t, String.t) :: OAuth2.AccessToken.t
  @callback oauth2_refresh(OAuth2.AccessToken.t) :: OAuth2.AccessToken.t
  @callback callback(Plug.Conn.t, map()) :: Any
end
