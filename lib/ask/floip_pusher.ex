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
          join: survey in Survey, on: endpoint.survey_id == survey.id,
          where: survey.state == "running" or survey.state == "terminated",
          order_by: endpoint.survey_id

      query
      |> preload(:survey)
      |> Repo.all
      |> Enum.map(fn(endpoint) ->
        {responses, first_response, last_response} = FloipPackage.responses(endpoint.survey, after_cursor: endpoint.last_pushed_response_id)

        case push_responses(endpoint, responses, state) do
          {:ok, _} ->
            endpoint = Ecto.Changeset.change(endpoint, last_pushed_response_id: Enum.at(last_response, 1))
            Repo.update!(endpoint)
          {:error, _} -> :error
        end
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

  defp push_responses(endpoint, responses, state) do
    {:ok, body} = Poison.encode(responses)
    request = {
      String.to_charlist("#{endpoint.uri}/flow-results/packages/#{endpoint.survey.floip_package_id}/responses"),
      [],
      'application/vnd.api+json',
      String.to_charlist(body)
    }

    {:ok, _} = :httpc.request(:post, request, [], [])
  end
end