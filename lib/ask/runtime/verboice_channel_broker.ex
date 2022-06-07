defmodule Ask.Runtime.VerboiceChannelBroker do
  def call(channel, params) do
    channel.client
      |> Verboice.Client.call(params)
      |> Ask.Runtime.VerboiceChannel.process_call_response()
  end
end
