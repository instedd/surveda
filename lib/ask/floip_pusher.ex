defmodule Ask.FloipPusher do
  use GenServer
  require Logger

  import Ecto.Query
  import Ecto

  alias Ask.{Repo, FloipEndpoint, FloipPackage, Survey}

  @poll_interval :timer.minutes(60)
  @server_ref {:global, __MODULE__}

  def server_ref, do: @server_ref

  def start_link do
    GenServer.start_link(__MODULE__, [], name: @server_ref)
  end

  # This method is a convenience to be used by tests.
  def poll do
    GenServer.call(@server_ref, :poll)
  end

  def init(_args) do
    :timer.send_after(1000, :poll)
    Logger.info "FLOIP pusher started."
    {:ok, nil}
  end

  def handle_info(:poll, state, now) do
    try do
      query =
        from endpoint in FloipEndpoint,
          order_by: endpoint.survey_id

      query
      |> preload(:survey)
      |> Repo.all
      |> Enum.map(fn(endpoint) ->
        {responses, first_response, last_response} = FloipPackage.responses(endpoint.survey, after_cursor: endpoint.last_pushed_response_id)
        endpoint = Ecto.Changeset.change(endpoint, last_pushed_response_id: Enum.at(last_response, 1))
        Repo.update!(endpoint)
      end)

      {:ok, state}
    after
      :timer.send_after(@poll_interval, :poll)
    end
  end

  def handle_info(:poll, state) do
    handle_info(:poll, state, Timex.now)
  end

  def handle_call(:poll, _from, state) do
    handle_info(:poll, state)
    {:reply, :ok, state}
  end
end