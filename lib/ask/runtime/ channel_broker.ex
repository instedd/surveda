defprotocol Ask.Runtime.ChannelBroker do
  def setup(channel, respondent, token, not_before, not_after)
  def ask(channel, respondent, token, prompts)
end
