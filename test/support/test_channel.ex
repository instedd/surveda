defmodule Ask.TestChannel do
  @behaviour Ask.Runtime.ChannelProvider
  defstruct [:pid, :has_queued_message, :delivery, :message_expired, :test_id]

  def new() do
    %Ask.TestChannel{pid: self()}
  end

  def new(:expired) do
    %Ask.TestChannel{pid: self(), message_expired: true, delivery: false}
  end

  def new(has_queued_message) when is_boolean(has_queued_message) do
    %Ask.TestChannel{pid: self(), has_queued_message: has_queued_message}
  end

  def new(channel) do
    %Ask.TestChannel{
      pid: channel.settings["pid"] |> Base.decode64! |> :erlang.binary_to_term,
      has_queued_message: channel.settings["has_queued_message"] |> String.to_atom,
      delivery: channel.settings["delivery"] |> String.to_atom,
      message_expired: channel.settings["message_expired"] |> String.to_atom,
      test_id: channel.settings["test_id"]
    }
  end

  def new(has_queued_message, delivery) do
    %Ask.TestChannel{pid: self(), has_queued_message: has_queued_message, delivery: delivery}
  end

  def settings(channel, test_id \\ nil) do
    %{
      "pid" => channel.pid |> :erlang.term_to_binary |> Base.encode64,
      "has_queued_message" => Atom.to_string(channel.has_queued_message),
      "delivery" => Atom.to_string(channel.delivery),
      "message_expired" => Atom.to_string(channel.message_expired),
      "test_id" => test_id
    }
  end

  def oauth2_authorize(_code, _redirect_uri, _base_url) do
    random_access_token()
  end

  def oauth2_refresh(%OAuth2.AccessToken{}, _base_url) do
    random_access_token()
  end

  def sync_channels(user_id, base_url) do
    user = Ask.User |> Ask.Repo.get(user_id)
    user
    |> Ecto.build_assoc(:channels)
    |> Ask.Channel.changeset(%{name: "test", provider: "test", base_url: base_url, type: "ivr", settings: %{}})
    |> Ask.Repo.insert!
  end

  def create_channel(user, base_url, api_channel) do
    user
    |> Ecto.build_assoc(:channels)
    |> Ask.Channel.changeset(%{name: "test", provider: "test", base_url: base_url, type: "ivr", settings: api_channel})
    |> Ask.Repo.insert!
  end

  def callback(_conn, _params) do
  end

  defp random_access_token do
    %OAuth2.AccessToken{
      access_token: :crypto.strong_rand_bytes(27) |> Base.encode64,
      expires_at: OAuth2.Util.unix_now + 3600
    }
  end
end

defimpl Ask.Runtime.Channel, for: Ask.TestChannel do
  def prepare(channel, callback_url) do
    send channel.pid, [:prepare, channel, callback_url]
    :ok
  end

  def setup(channel, respondent, token, _not_before, _not_after) do
    send channel.pid, [:setup, channel, respondent, token]
    {:ok, 0}
  end

  def ask(channel, respondent, token, prompts) do
    send channel.pid, [:ask, channel, respondent, token, prompts]
    respondent
  end

  def has_delivery_confirmation?(%{delivery: delivery}), do: delivery

  def has_queued_message?(%{has_queued_message: has_queued_message}, _), do: has_queued_message

  def message_expired?(%{message_expired: message_expired}, _), do: message_expired

  def cancel_message(channel, channel_state) do
    send channel.pid, [:cancel_message, channel, channel_state]
    :ok
  end

  def check_status(channel) do
    send channel.pid, [:check_status, channel]
    :up
  end
end
