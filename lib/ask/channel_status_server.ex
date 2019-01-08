defmodule Ask.ChannelStatusServer do
  use GenServer
  require Logger

  alias Ask.Survey

  @server_ref {:global, __MODULE__}
  @poll_interval :timer.minutes(5)

  def server_ref, do: @server_ref

  def start_link do
    GenServer.start_link(__MODULE__, %{}, name: @server_ref)
  end

  def init(state) do
    :timer.send_after(@poll_interval, :poll)
    log_info "started."
    {:ok, state}
  end

  def poll(pid) do
    send(pid, :poll)
  end

  def get_channel_status(channel_id) do
    GenServer.call(@server_ref, {:get_channel_status, channel_id})
  end

  defp update_channel_status(channel_id, channel_status) do
    GenServer.cast(@server_ref, {:update, {channel_id, channel_status}})
  end

  def handle_call({:get_channel_status, channel_id}, _from, state) do
    {:reply, state[channel_id] || :unknown, state}
  end

  def handle_info(:poll, state) do
    try do
      Survey.running_channels()
      |> Enum.each(fn c ->
        runtime_channel = Ask.Channel.runtime_channel(c)
        spawn(fn ->
          status = Ask.Runtime.Channel.check_status(runtime_channel)
          update_channel_status(c.id, status)
        end)
      end)

      {:noreply, state}
    after
      :timer.send_after(@poll_interval, :poll)
    end
  end

  def handle_cast({:update, {channel_id, channel_status}}, state) do
    {:noreply, state |> Map.put(channel_id, channel_status)}
  end

  defp log_info(message) do
    Logger.info("ChannelStatusServer: #{message}")
  end
end
