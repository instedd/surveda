alias Ask.Runtime.NuntiumChannel

defmodule Ask.Runtime.NuntiumChannelBroker do
  def ask(channel, respondent, token, reply) do
    to = "sms://#{respondent.sanitized_phone_number}"

    messages =
      NuntiumChannel.reply_to_messages(reply, to, respondent.id)
      |> Enum.map(fn msg ->
        Map.merge(msg, %{
          suggested_channel: channel.settings["nuntium_channel"],
          channel: channel.settings["nuntium_channel"],
          session_token: token
        })
      end)

    respondent = NuntiumChannel.update_stats(respondent)

    Nuntium.Client.new(channel.base_url, channel.oauth_token)
    |> Nuntium.Client.send_ao(channel.settings["nuntium_account"], messages)

    respondent
  end
end
