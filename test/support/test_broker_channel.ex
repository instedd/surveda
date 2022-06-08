defmodule Ask.TestChannelBroker do
  defimpl Ask.Runtime.ChannelBroker, for: Ask.TestChannel do
    def setup(channel, respondent, token, _not_before, _not_after) do
      send(channel.pid, [:setup, channel, respondent, token])
      {:ok, 0}
    end

    def ask(channel, respondent, token, prompts) do
      send(channel.pid, [:ask, channel, respondent, token, prompts])
      respondent
    end
  end
end
