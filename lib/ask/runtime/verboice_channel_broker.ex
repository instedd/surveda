alias Ask.Runtime.VerboiceChannel

defmodule Ask.Runtime.VerboiceChannelBroker do
  def setup(channel, respondent, token, not_before, not_after) do
    in_five_seconds = Timex.shift(not_before, seconds: 5)
    channel_base_url = channel.client.base_url

    params = [
      address: respondent.sanitized_phone_number,
      callback_url: VerboiceChannel.callback_url(respondent, channel_base_url),
      status_callback_url:
        VerboiceChannel.status_callback_url(respondent, channel_base_url, token),
      not_before: in_five_seconds,
      not_after: not_after
    ]

    params =
      if channel.channel_id do
        Keyword.put(params, :channel_id, channel.channel_id)
      else
        Keyword.put(params, :channel, channel.channel_name)
      end

    channel.client
      |> Verboice.Client.call(params)
      |> VerboiceChannel.process_call_response()
  end
end
