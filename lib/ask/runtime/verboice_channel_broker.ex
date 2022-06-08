alias Ask.Runtime.Channel

defmodule Ask.Runtime.VerboiceChannelBroker do
  defimpl Ask.Runtime.ChannelBroker, for: Ask.Runtime.VerboiceChannel do
    def ask(_, _, _, _), do: throw(:not_implemented)

    def setup(channel, respondent, token, not_before, not_after) do
      Channel.setup(channel, respondent, token, not_before, not_after)
    end
  end
end
