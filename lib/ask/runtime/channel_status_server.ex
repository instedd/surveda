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
        runtime_channel = Ask.Channel.runtime_channel(c)
        previous_status = get_status_from_state(c.id, state)

        spawn(fn ->
          status = ChannelBroker.check_status(runtime_channel)
          timestamp = Timex.now()

          case status do
            {:down, messages} ->
              case previous_status do
                %{status: :down} ->
                  nil

                _ ->
                  AskWeb.Email.channel_down(c.user.email, c, messages) |> Ask.Mailer.deliver()

                  update_channel_status(c.id, %{
                    status: :down,
                    messages: messages,
                    name: c.name,
                    timestamp: timestamp
                  })
              end

            {:error, code} ->
              case previous_status do
                %{status: :error} ->
                  nil

                _ ->
                  AskWeb.Email.channel_error(c.user.email, c, code) |> Ask.Mailer.deliver()

                  update_channel_status(c.id, %{
                    status: :error,
                    code: code,
                    name: c.name,
                    timestamp: timestamp
                  })
              end

            status ->
              update_channel_status(c.id, status)
          end
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

  def get_status_from_state(channel_id, state) do
    state[channel_id] || :unknown
  end

  def log_info(message) do
    Logger.info("ChannelStatusServer: #{message}")
  end
end
