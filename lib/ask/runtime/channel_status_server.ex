defmodule Ask.Runtime.ChannelStatusServer do
  use GenServer
  require Logger

  alias Ask.{Repo, Survey}

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
    {:reply, get_status_from_state(channel_id, state), state}
  end

  def handle_info(:poll, state) do
    try do
      Survey.running_channels()
      |> Repo.preload(:user)
      |> Enum.each(fn c ->
        runtime_channel = Ask.Channel.runtime_channel(c)
        previous_status = get_status_from_state(c.id, state)
        spawn(fn ->
          status = Ask.Runtime.Channel.check_status(runtime_channel)
          timestamp = Timex.now
          case status do
            {:down, messages} ->
              if (previous_status == :up) || (previous_status == :unknown) do
                Ask.Email.channel_down(c.user.email, c, messages) |> Ask.Mailer.deliver
                update_channel_status(c.id, status |> to_map_or_symbol(c.name, timestamp))
              end
            _ -> update_channel_status(c.id, status |> to_map_or_symbol(c.name, timestamp))
          end
        end)
      end)

      {:noreply, state}
    after
      :timer.send_after(@poll_interval, :poll)
    end
  end

  def to_map_or_symbol({:down, messages}, name, timestamp) do
    %{status: :down, messages: messages, name: name, timestamp: timestamp}
  end
  def to_map_or_symbol({:error, messages}, name, timestamp) do
    %{status: :error, messages: messages, name: name, timestamp: timestamp}
  end
  def to_map_or_symbol(:up, _, _), do: :up
  def to_map_or_symbol(:unknown, _, _), do: :unknown

  def handle_cast({:update, {channel_id, channel_status}}, state) do
    {:noreply, state |> Map.put(channel_id, channel_status)}
  end

  def get_status_from_state(channel_id, state) do
    state[channel_id] || :unknown
  end

  def log_info(message) do
    Logger.info("ChannelStatusServer: #{message}")
  end
end
