alias Ask.Runtime.Channel

defmodule Ask.Runtime.ChannelBroker do
  def prepare(channel) do
    Channel.prepare(channel)
  end

  def setup(channel, respondent, token, not_before, not_after) do
    Channel.setup(channel, respondent, token, not_before, not_after)
  end

  def has_delivery_confirmation?(channel) do
    Channel.has_delivery_confirmation?(channel)
  end

  def ask(channel, respondent, token, reply) do
    Channel.ask(channel, respondent, token, reply)
  end

  def has_queued_message?(channel, channel_state) do
    Channel.has_queued_message?(channel, channel_state)
  end

  def cancel_message(channel, channel_state) do
    Channel.cancel_message(channel, channel_state)
  end

  def message_expired?(channel, channel_state) do
    Channel.message_expired?(channel, channel_state)
  end

  def check_status(channel) do
    Channel.check_status(channel)
  end
end
