defmodule Ask.Runtime.NuntiumChannelBroker do
  def send_ao(channel, messages) do
    Nuntium.Client.new(channel.base_url, channel.oauth_token)
    |> Nuntium.Client.send_ao(channel.settings["nuntium_account"], messages)
  end
end
