defmodule Ask.Runtime.ChannelStatusServer do
  use GenServer
  require Logger

  alias Ask.{Repo, Survey}
  alias Ask.Runtime.ChannelBroker

  @server_ref {:global, __MODULE__}
  @poll_interval :timer.minutes(5)

  def server_ref, do: @server_ref

  def start_link do
    GenServer.start_link(__MODULE__, %{}, name: @server_ref)
  end

  def init(state) do
    :timer.send_after(@poll_interval, :poll)
    log_info("started.")
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
    {:reply, get_status_from_state(channel_id, state), state}
  end

  def handle_info(:poll, state) do
    log_info("polling")

    try do
      Survey.running_channels()
      |> Repo.preload(:user)
      |> Enum.each(fn c ->

        unless c.paused do
          previous_status = get_status_from_state(c.id, state)

          spawn(fn ->
            status = ChannelBroker.check_status(c.id)
            timestamp = Timex.now()

            process_channel_status_change(status, previous_status, timestamp, c)
          end)
        end
      end)

      {:noreply, state}
    after
      :timer.send_after(@poll_interval, :poll)
    end
  end

  def handle_cast({:update, {channel_id, channel_status}}, state) do
    {:noreply, state |> Map.put(channel_id, channel_status)}
  end

  def get_status_from_state(channel_id, state) do
    state[channel_id] || :unknown
  end

  def log_info(message) do
    Logger.info("ChannelStatusServer: #{message}")
  end

  defp process_channel_status_change({:down, _messages}, %{status: :down}, _timestamp, _channel) do
    nil
  end

  defp process_channel_status_change({:down, messages}, _previous_status, timestamp, channel) do
    AskWeb.Email.channel_down(channel.user.email, channel, messages) |> Ask.Mailer.deliver()

    update_channel_status(channel.id, %{
      status: :down,
      messages: messages,
      name: channel.name,
      timestamp: timestamp
    })
  end

  defp process_channel_status_change({:error, _code}, %{status: :error}, _timestamp, _channel) do
    nil
  end

  defp process_channel_status_change({:error, code}, _previous_status, timestamp, channel) do
    AskWeb.Email.channel_error(channel.user.email, channel, code) |> Ask.Mailer.deliver()

    update_channel_status(channel.id, %{
      status: :error,
      code: code,
      name: channel.name,
      timestamp: timestamp
    })
  end

  defp process_channel_status_change(status, _previous_status, _timestamp, channel) do
    update_channel_status(channel.id, status)
  end
end
