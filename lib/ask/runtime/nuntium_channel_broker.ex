alias Ask.Runtime.Channel

defmodule Ask.Runtime.NuntiumChannelBroker do
  defimpl Ask.Runtime.ChannelBroker, for: Ask.Runtime.NuntiumChannel do
    def setup(_channel, _respondent, _token, _not_before, _not_after), do: :ok

    def ask(channel, respondent, token, reply) do
      Channel.ask(channel, respondent, token, reply)
    end
  end
end
