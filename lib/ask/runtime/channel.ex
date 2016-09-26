defprotocol Ask.Runtime.Channel do
  def ask(channel, phone_number, prompts)
end

defmodule Ask.Runtime.ChannelProvider do
  @callback new(map()) :: Ask.Runtime.Channel
  @callback oauth2_authorize(String.t, String.t) :: OAuth2.AccessToken.t
end
