defmodule Ask.TestChannel do
  @behaviour Ask.Runtime.ChannelProvider
  defstruct [:pid, :push]

  def new(push \\ true)

  def new(push) when is_atom(push) do
    %Ask.TestChannel{pid: self(), push: push}
  end

  def new(channel) do
    pid = channel.settings["pid"] |> Base.decode64! |> :erlang.binary_to_term
    push = channel.settings["push"] |> String.to_atom
    %Ask.TestChannel{pid: pid, push: push}
  end

  def settings(channel) do
    encoded_pid = channel.pid |> :erlang.term_to_binary |> Base.encode64
    encoded_push = channel.push |> Atom.to_string
    %{"pid" => encoded_pid, "push" => encoded_push}
  end

  def oauth2_authorize(_code, _redirect_uri, _callback_uri) do
    random_access_token
  end

  def oauth2_refresh(%OAuth2.AccessToken{}) do
    random_access_token
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
  def setup(channel, phone_number) do
    send channel.pid, [:setup, channel, phone_number]
  end

  def can_push_question?(channel) do
    channel.push
  end

  def ask(channel, phone_number, prompts) do
    send channel.pid, [:ask, channel, phone_number, prompts]
  end
end
