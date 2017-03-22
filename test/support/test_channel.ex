defmodule Ask.TestChannel do
  @behaviour Ask.Runtime.ChannelProvider
  defstruct [:pid, :push, :has_queued_message, :delivery]

  def new(push \\ true)

  def new(push) when is_atom(push) do
    new(push, nil, push)
  end

  def new(channel) do
    pid = channel.settings["pid"] |> Base.decode64! |> :erlang.binary_to_term
    push = channel.settings["push"] |> String.to_atom
    has_queued_message = channel.settings["has_queued_message"] |> String.to_atom
    %Ask.TestChannel{pid: pid, push: push, has_queued_message: has_queued_message, delivery: push}
  end

  def new(push, has_queued_message) do
    new(push, has_queued_message, push)
  end

  def new(push, has_queued_message, delivery) do
    %Ask.TestChannel{pid: self(), push: push, has_queued_message: has_queued_message, delivery: delivery}
  end

  def settings(channel) do
    encoded_pid = channel.pid |> :erlang.term_to_binary |> Base.encode64
    encoded_push = channel.push |> Atom.to_string
    encoded_has_queued_message = channel.has_queued_message |> Atom.to_string
    %{"pid" => encoded_pid, "push" => encoded_push, "has_queued_message" => encoded_has_queued_message}
  end

  def oauth2_authorize(_code, _redirect_uri, _callback_uri) do
    random_access_token
  end

  def oauth2_refresh(%OAuth2.AccessToken{}) do
    random_access_token
  end

  def sync_channels(user_id) do
    user = Ask.User |> Ask.Repo.get(user_id)
    user
    |> Ecto.build_assoc(:channels)
    |> Ask.Channel.changeset(%{name: "test", provider: "test", type: "ivr", settings: %{}})
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

  def setup(channel, respondent, token) do
    send channel.pid, [:setup, channel, respondent, token]
    {:ok, 0}
  end

  def can_push_question?(channel) do
    channel.push
  end

  def has_delivery_confirmation?(channel) do
    channel.delivery
  end

  def ask(channel, respondent, token, prompts) do
    send channel.pid, [:ask, channel, respondent, token, prompts]
  end

  def has_queued_message?(channel, _channel_state) do
    channel.has_queued_message
  end

  def cancel_message(channel, channel_state) do
    send channel.pid, [:cancel_message, channel, channel_state]
    :ok
  end
end
