defmodule Ask.Runtime.ChannelAgent do
  use GenServer

  alias Ask.{Channel, Logger, OAuthToken, Repo, Runtime}

  @server_ref {:global, __MODULE__}

  def start_link do
    GenServer.start_link(__MODULE__, [], name: @server_ref)
  end

  def init([]) do
    Logger.info("ChannelAgent started.")
    {:ok, %{}}
  end

  @spec get(integer) :: Runtime.Channel.t
  def get(channel_id) do
    GenServer.call(@server_ref, {:get, channel_id})
  end

  @spec clear() :: :ok
  def clear do
    # TODO: consider async cast/handle cast
    GenServer.call(@server_ref, :clear)
  end

  def handle_call({:get, channel_id}, _, state) do
    current = Map.get(state, channel_id)

    {state, runtime_channel} =
      if current do
        if OAuthToken.about_to_expire?(current.access_token) do
          create(state, channel_id)
        else
          {state, current}
        end
      else
        create(state, channel_id)
      end

    {:reply, runtime_channel, state}
  end

  def handle_call(:clear, _, _) do
    {:reply, :ok, %{}}
  end

  if Mix.env() == :test do
    defp create(state, nil) do
      IO.inspect({:missing_channel_id})
      {state, nil}
    end
  end

  defp create(state, channel_id) do
    case Channel |> Repo.get(channel_id) do
      nil -> {state, nil}
      channel ->
        runtime_channel = Channel.provider(channel.provider).new(channel)
        new_state = state |> Map.put(channel_id, runtime_channel)
        {new_state, runtime_channel}
    end
  end
end
