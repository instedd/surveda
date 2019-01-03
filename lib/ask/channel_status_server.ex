defmodule Ask.ChannelStatusServer do
  use GenServer
  require Logger

  alias Ask.Survey

  @server_ref {:global, __MODULE__}
  # @poll_interval :timer.seconds(1)

  def server_ref, do: @server_ref

  def start_link do
    GenServer.start_link(__MODULE__, %{}, name: @server_ref)
  end

  def init(state) do
    log_info "started."
    {:ok, state}
  end

  def poll() do
    GenServer.cast(@server_ref, :poll)
  end

  def get_channel_status(channel_id) do
    GenServer.call(@server_ref, {:get_channel_status, channel_id})
  end

  def update(channel_id, channel_status) do
    GenServer.cast(@server_ref, {:update, {channel_id, channel_status}})
  end

  def handle_call({:get_channel_status, channel_id}, _from, state) do
    {:reply, state[channel_id] || :unknown, state}
  end

  def handle_cast(:poll, state) do
    Survey.running_channels()
    |> Enum.each(fn c ->
      runtime_channel = Ask.Channel.runtime_channel(c)
      spawn(fn ->
        Ask.Runtime.Channel.check_status(runtime_channel)
      end)
    end)

    {:noreply, state}
  end

  def handle_cast({:update, {channel_id, channel_status}}, state) do
    {:noreply, state |> Map.put(channel_id, channel_status)}
  end

  defp log_info(message) do
    Logger.info("ChannelStatusServer: #{message}")
  end
end
