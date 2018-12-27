defmodule Ask.ChannelStatusServer do
  use GenServer
  require Logger

  @server_ref {:global, __MODULE__}

  def server_ref, do: @server_ref

  def start_link do
    GenServer.start_link(__MODULE__, %{}, name: @server_ref)
  end

  def init(state) do
    :timer.send_interval(1000, :timer)
    log_info "started."
    {:ok, state}
  end

  def handle_info(:timer, state) do
    {:noreply, state}
  end

  def getChannelStatus(pid, channel_id) do
    GenServer.call(pid, {:get_channel_status, channel_id})
  end

  def update(pid, channel_id, channel_status) do
    GenServer.cast(pid, {:update, {channel_id, channel_status}})
  end

  def handle_call({:get_channel_status, channel_id}, _from, state) do
    {:reply, state[channel_id] || :unknown, state}
  end

  def handle_cast({:update, {channel_id, channel_status}}, state) do
    {:noreply, state |> Map.put(channel_id, channel_status)}
  end

  defp log_info(message) do
    Logger.info("ChannelStatusServer: #{message}")
  end

  # defp log_error(message) do
  #   Logger.error("ChanelStatusServer: #{message}")
  # end
end
