defmodule Ask.TestChannel do
  @behaviour Ask.Runtime.ChannelProvider
  defstruct [:pid]

  def new do
    %Ask.TestChannel{pid: self()}
  end

  def new(channel) do
    pid = channel.settings["pid"] |> Base.decode64! |> :erlang.binary_to_term
    %Ask.TestChannel{pid: pid}
  end

  def settings(channel) do
    encoded_pid = channel.pid |> :erlang.term_to_binary |> Base.encode64
    %{"pid" => encoded_pid}
  end

  def oauth2_authorize(_code, _redirect_uri) do
    %OAuth2.AccessToken{}
  end
end

defimpl Ask.Runtime.Channel, for: Ask.TestChannel do
  def ask(channel, phone_number, prompts) do
    send channel.pid, [:ask, channel, phone_number, prompts]
  end
end
