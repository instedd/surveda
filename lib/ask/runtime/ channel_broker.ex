alias Ask.Runtime.Channel

defmodule Ask.Runtime.ChannelBroker do
  def setup(channel, respondent, token, not_before, not_after) do
    Channel.setup(channel, respondent, token, not_before, not_after)
  end

  def ask(channel, respondent, token, reply) do
    Channel.ask(channel, respondent, token, reply)
  end
end
