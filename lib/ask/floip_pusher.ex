defmodule Ask.FloipPusher do
  use GenServer
  require Logger

  import Ecto.Query

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
    log_info "started."
    {:ok, nil}
  end

  def handle_info(:poll, state, _now) do
    try do
      query =
        from endpoint in FloipEndpoint,
          join: survey in Survey, on: endpoint.survey_id == survey.id,
          where: survey.state == "running" or survey.state == "terminated",
          where: endpoint.retries < 10,
          where: endpoint.state == "enabled",
          order_by: endpoint.survey_id

      query
      |> preload(:survey)
      |> Repo.all
      |> Enum.map(fn(endpoint) ->
        {responses, _first_response, last_response} =
          FloipPackage.responses(endpoint.survey, after_cursor: endpoint.last_pushed_response_id, size: 1000)

        responses_payload = FloipPackage.responses_for_aggregator(endpoint.survey, responses)

        if length(responses) > 0 do
          try do
            :ok = push_responses(endpoint, responses_payload)
            endpoint =
              Ecto.Changeset.change(endpoint, last_pushed_response_id: Enum.at(last_response, 1), retries: 0)
            Repo.update!(endpoint)
          rescue
            error ->
              log_error("failed to push to endpoint #{show(endpoint)}: #{inspect(error)}")
              {new_retries, new_state} = if (endpoint.retries == 9), do: {0, "disabled"}, else: {endpoint.retries + 1, endpoint.state}
              endpoint_change = Ecto.Changeset.change(endpoint, retries: new_retries, state: new_state)
              Repo.update!(endpoint_change)
              log_info("retries was #{endpoint.retries}, now it is #{endpoint_change.changes[:retries]}")
          end
        else
          if endpoint.survey.state == "terminated" do
            endpoint_change = Ecto.Changeset.change(endpoint, state: "terminated")
            Repo.update!(endpoint_change)
            Logger.info("Marking endpoint #{show(endpoint)} as 'terminated' because we have already pushed all messages to it and the survey is terminated.")
          else
            Logger.info("No new responses for endpoint #{show(endpoint)}.")
          end
        end
      end)

      {:ok, state}
    after
      :timer.send_after(@poll_interval, :poll)
    end
  end

  defp show(endpoint) do
    "(survey: #{endpoint.survey.id}, uri: #{endpoint.uri})"
  end

  defp log_info(message) do
    Logger.info("FLOIP pusher: #{message}")
  end

  defp log_error(message) do
    Logger.error("FLOIP pusher: #{message}")
  end

  def handle_info(:poll, state) do
    handle_info(:poll, state, Timex.now)
  end

  def handle_call(:poll, _from, state) do
    handle_info(:poll, state)
    {:reply, :ok, state}
  end

  def create_package(survey, endpoint, responses_uri) do
    {:ok, body} = FloipPackage.descriptor(survey, responses_uri) |> Poison.encode

    endpoint_uri = String.to_charlist("#{endpoint.uri}/flow-results/packages")

    request = {
      endpoint_uri,
      [{String.to_charlist("authorization"), String.to_charlist(endpoint.auth_token)}],
      'application/vnd.api+json',
      String.to_charlist(body)
    }

    response = :httpc.request(:post, request, [], [])
    {:ok, {{_, status_code, _}, _, _}} = response

    case status_code do
      200 -> :ok
      201 -> :ok
      _ -> {:error, response}
    end
  end

  defp push_responses(endpoint, responses) do
    {:ok, body} = Poison.encode(responses)

    endpoint_uri = String.to_charlist("#{endpoint.uri}/flow-results/packages/#{endpoint.survey.floip_package_id}/responses")

    request = {
      endpoint_uri,
      [{String.to_charlist("Authorization"), String.to_charlist(endpoint.auth_token)}],
      'application/vnd.api+json',
      String.to_charlist(body)
    }

    Logger.info("Attempting push to #{endpoint.uri}, survey id: #{endpoint.survey.id}")
    response = :httpc.request(:post, request, [], [])

    {:ok, {{_, status_code, _}, _, _}} = response

    case status_code do
      200 -> :ok
      201 -> :ok
      _ -> {:error, response}
    end
  end
end