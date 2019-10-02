defmodule FloipPusherTest do
  use Ask.ModelCase
  use Ask.LogHelper
  alias Ask.{Repo, FloipPusher, FloipEndpoint, Response}

  setup do
    server = Bypass.open
    Process.put(:port, server.port)
    {:ok, server: server}
  end

  defp insert_response(survey) do
    respondent = insert(:respondent, survey: survey)
    insert(:response, respondent: respondent)
  end

  defp insert_endpoint(survey), do: insert_endpoint(survey, [])
  defp insert_endpoint(survey, opts) do
    insert(:floip_endpoint, [survey_id: survey.id] ++ opts)
  end

  defp assert_last_response(survey, endpoint, response_id) do
    endpoint = Repo.get_by(FloipEndpoint, uri: endpoint.uri, survey_id: survey.id)
    assert endpoint.last_pushed_response_id == response_id
  end

  defp expect_push_success(server, endpoint_namespace, package_id) do
    {200, ""}
    |> expect_push(server, endpoint_namespace, package_id)
  end

  defp expect_push_fail(server, endpoint_namespace, package_id) do
    {500, ""}
    |> expect_push(server, endpoint_namespace, package_id)
  end

  defp expect_push({return_status, return_message}, server, endpoint_namespace, package_id) do
    Bypass.expect_once server, "POST", "/#{endpoint_namespace}/flow-results/packages/#{package_id}/responses", fn conn ->
      Plug.Conn.resp(conn, return_status, return_message)
    end
    server
  end

  defp expect_success_always(server) do
    Bypass.expect server, fn conn ->
      Plug.Conn.resp(conn, 200, "")
    end
    server
  end

  defp assert_retries(endpoint, retries) do
    endpoint = Repo.get_by(FloipEndpoint, uri: endpoint.uri, survey_id: endpoint.survey_id)
    assert endpoint.retries == retries
  end

  defp run_pusher_without_logging() do
    without_logging do
      {:ok, _} = FloipPusher.start_link
      FloipPusher.poll
    end
  end

  test "writes last successfully pushed response for each endpoint", %{server: server} do
    # 2 running surveys
    survey1 = insert(:survey, state: "running")
    survey2 = insert(:survey, state: "running")

    # 2 endpoints per survey
    endpoint_1_survey_1 = insert_endpoint(survey1)
    endpoint_2_survey_1 = insert_endpoint(survey1)
    endpoint_1_survey_2 = insert_endpoint(survey2)
    endpoint_2_survey_2 = insert_endpoint(survey2)

    # 2 responses per survey
    _response_1_survey_1 = insert_response(survey1)
    response_2_survey_1 = insert_response(survey1)
    _response_1_survey_2 = insert_response(survey2)
    response_2_survey_2 = insert_response(survey2)

    server |> expect_success_always

    # Run the pusher
    run_pusher_without_logging()

    # Verify that each endpoint ends up with the right last_response_id set
    assert_last_response(survey1, endpoint_1_survey_1, response_2_survey_1.id)
    assert_last_response(survey1, endpoint_2_survey_1, response_2_survey_1.id)
    assert_last_response(survey2, endpoint_1_survey_2, response_2_survey_2.id)
    assert_last_response(survey2, endpoint_2_survey_2, response_2_survey_2.id)
  end

  test "pushes to all endpoints that have new responses", %{server: server} do
    # 2 running surveys
    survey1 = insert(:survey, state: "running")
    survey2 = insert(:survey, state: "running")

    # 2 endpoints per survey
    insert_endpoint(survey1, uri: "http://localhost:#{server.port}/1.1")
    insert_endpoint(survey1, uri: "http://localhost:#{server.port}/2.1")
    insert_endpoint(survey2, uri: "http://localhost:#{server.port}/1.2")
    insert_endpoint(survey2, uri: "http://localhost:#{server.port}/2.2")

    # 2 responses per survey
    insert_response(survey1)
    insert_response(survey1)
    insert_response(survey2)
    insert_response(survey2)

    server
    |> expect_push_success("1.1", survey1.floip_package_id)
    |> expect_push_success("2.1", survey1.floip_package_id)
    |> expect_push_success("1.2", survey2.floip_package_id)
    |> expect_push_success("2.2", survey2.floip_package_id)

    # Run the pusher
    run_pusher_without_logging()
  end

  test "does not overwrite last_pushed_response_id if push fails", %{server: server} do
    # 2 running surveys
    survey1 = insert(:survey, state: "running")
    survey2 = insert(:survey, state: "running")

    # 2 endpoints per survey
    endpoint_1_survey_1 = insert_endpoint(survey1, uri: "http://localhost:#{server.port}/1.1")
    endpoint_2_survey_1 = insert_endpoint(survey1, uri: "http://localhost:#{server.port}/2.1")
    endpoint_1_survey_2 = insert_endpoint(survey2, uri: "http://localhost:#{server.port}/1.2")
    endpoint_2_survey_2 = insert_endpoint(survey2, uri: "http://localhost:#{server.port}/2.2")

    # 2 responses per survey
    insert_response(survey1)
    response_2_survey_1 = insert_response(survey1)
    insert_response(survey2)
    response_2_survey_2 = insert_response(survey2)

    # Set up the mock to fail for one of the endpoints
    server |> expect_success_always
    server |> expect_push_fail("1.1", survey1.floip_package_id)

    # Run the pusher
    run_pusher_without_logging()

    # Verify that last_pushed_response_id hasn't changed for the failing endpoint
    assert_last_response(survey1, endpoint_1_survey_1, nil)

    # Verify that last_pushed_response_id has changed for succeeding endpoints
    assert_last_response(survey1, endpoint_2_survey_1, response_2_survey_1.id)
    assert_last_response(survey2, endpoint_1_survey_2, response_2_survey_2.id)
    assert_last_response(survey2, endpoint_2_survey_2, response_2_survey_2.id)
  end

  test "does not push to endpoints with no new responses", %{server: server} do
    # 2 running surveys
    survey1 = insert(:survey, state: "running")
    survey2 = insert(:survey, state: "running")

    # 2 responses per survey
    insert_response(survey1)
    response_2_survey_1 = insert_response(survey1)
    insert_response(survey2)
    insert_response(survey2)

    # 2 endpoints per survey
    # On one of the endpoints, set last_response_id to the latest response in the survey
    insert_endpoint(survey1, uri: "http://localhost:#{server.port}/1.1", last_pushed_response_id: response_2_survey_1.id)
    insert_endpoint(survey1, uri: "http://localhost:#{server.port}/2.1")
    insert_endpoint(survey2, uri: "http://localhost:#{server.port}/1.2")
    insert_endpoint(survey2, uri: "http://localhost:#{server.port}/2.2")

    # Verify that the receiving mock gets one POST for each endpoint, except the one that already had the last response
    server
    |> expect_push_success("2.1", survey1.floip_package_id)
    |> expect_push_success("1.2", survey2.floip_package_id)
    |> expect_push_success("2.2", survey2.floip_package_id)

    # Run the pusher
    run_pusher_without_logging()
  end

  test "does not send more than 1000 responses per run per endpoint", %{server: server} do
    # 1 running survey
    survey = insert(:survey, state: "running")

    # Add 1 endpoint to the survey
    endpoint = insert_endpoint(survey, uri: "http://localhost:#{server.port}/1.1")

    # Add 2000 responses to the survey (all by the same respondent for convenience)
    respondent = insert(:respondent, survey: survey)
    insert_list(2000, :response, respondent: respondent)

    # Verify that the receiving mock gets the first 1000 responses
    Bypass.expect server, fn conn ->
      {:ok, responses, _} = Plug.Conn.read_body(conn)
      {:ok, responses} = Poison.decode(responses)

      assert length(responses["data"]["attributes"]["responses"]) == 1000
      Plug.Conn.resp(conn, 200, "")
    end

    # Run the pusher
    run_pusher_without_logging()

    # Verify the last pushed response is the 1000th.
    assert_last_response(survey, endpoint, (first(Response) |> Repo.one).id + 999)
  end

  test "increments endpoint retry counter if push fails", %{server: server} do
    # 1 running survey
    survey = insert(:survey, state: "running")

    # Add 1 endpoint to the survey
    endpoint = insert_endpoint(survey, uri: "http://localhost:#{server.port}/1.1")

    # Add 2 responses to the survey (all by the same respondent for convenience)
    respondent = insert(:respondent, survey: survey)
    insert_list(2, :response, respondent: respondent)

    # Configure receiving mock to fail
    server |> expect_push_fail("1.1", survey.floip_package_id)

    # Run poll
    run_pusher_without_logging()

    # Verify that the endpoint retry counter is now set at 1
    assert_retries(endpoint, 1)
  end

  test "resets endpoint retry counter if push succeeds", %{server: server} do
    # Create 1 survey
    survey = insert(:survey, state: "running")

    # Add 1 endpoint to the survey, with retry counter == 8
    endpoint = insert_endpoint(survey, uri: "http://localhost:#{server.port}/1.1", retries: 8)

    # Add 2 responses to the survey (all by the same respondent for convenience)
    respondent = insert(:respondent, survey: survey)
    insert_list(2, :response, respondent: respondent)

    # Any push attempt succeeds
    server |> expect_success_always

    # Run poll
    run_pusher_without_logging()

    # Verify that the endpoint retry counter is now set at 0
    assert_retries(endpoint, 0)
  end

  test "ignores endpoints with more than 10 retries because the receiving end is likely down", %{server: server} do
     # 2 running surveys
    survey1 = insert(:survey, state: "running")
    survey2 = insert(:survey, state: "running")

    # 2 responses per survey
    insert_response(survey1)
    insert_response(survey1)
    insert_response(survey2)
    insert_response(survey2)

    # Add 2 endpoints to each survey, one with 10 retries and one with 0 retries for each survey
    insert_endpoint(survey1, uri: "http://localhost:#{server.port}/1.1", retries: 10)
    insert_endpoint(survey1, uri: "http://localhost:#{server.port}/2.1", retries: 0)
    insert_endpoint(survey2, uri: "http://localhost:#{server.port}/1.2", retries: 10)
    insert_endpoint(survey2, uri: "http://localhost:#{server.port}/2.2", retries: 0)

    # 2 responses per survey
    insert_response(survey1)
    insert_response(survey1)
    insert_response(survey2)
    insert_response(survey2)

    # Verify that the receiving mock only gets posts for the 2 endpoints with 0 retries
    server
    |> expect_push_success("2.1", survey1.floip_package_id)
    |> expect_push_success("2.2", survey2.floip_package_id)

    # Run poll
    run_pusher_without_logging()
  end

  test "ignores disabled endpoints", %{server: server} do
    # 1 survey
    survey1 = insert(:survey, state: "running")

    # 1 endpoint in "disabled" state
    insert_endpoint(survey1, uri: "http://localhost:#{server.port}/1.1", retries: 0, state: "disabled")

    # 1 response
    insert_response(survey1)

    # Run poll expecting not to receive a push
    run_pusher_without_logging()
  end

  test "marks endpoint as disabled if it reaches 10 retries", %{server: server} do
    # 1 survey
    survey1 = insert(:survey, state: "running")

    # 1 endpoint with 9 retries
    endpoint = insert_endpoint(survey1, uri: "http://localhost:#{server.port}/1.1", retries: 9, state: "enabled")

    # 1 endpoint with 8 retries
    endpoint2 = insert_endpoint(survey1, uri: "http://localhost:#{server.port}/2.1", retries: 8, state: "enabled")

    # 1 response
    insert_response(survey1)

    # Setup endpoint to fail so that we reach the 10th retry
    server
    |> expect_push_fail("1.1", survey1.floip_package_id)
    |> expect_push_fail("2.1", survey1.floip_package_id)

    # Run poll
    run_pusher_without_logging()

    # The endpoint that has failed 10 times is now disabled
    endpoint = Repo.get_by(FloipEndpoint, uri: endpoint.uri, survey_id: survey1.id)
    assert endpoint.retries == 0
    assert endpoint.state == "disabled"

    # The endpoint that has failed 9 times is still enabled
    endpoint2 = Repo.get_by(FloipEndpoint, uri: endpoint2.uri, survey_id: survey1.id)
    assert endpoint2.retries == 9
    assert endpoint2.state == "enabled"
  end

  test "marks endpoint as terminated if survey terminated and last message was pushed", %{server: server} do
    # 1 survey terminated
    survey1 = insert(:survey, state: "terminated")

    # 1 response
    last_response = insert_response(survey1)

    # 1 endpoint whose last pushed response is the survey's last response
    endpoint = insert_endpoint(survey1, uri: "http://localhost:#{server.port}/1.1", last_pushed_response_id: last_response.id)

    # Pusher runs
    run_pusher_without_logging()

    # Endpoint state is now "terminated"
    endpoint = Repo.get_by(FloipEndpoint, uri: endpoint.uri, survey_id: survey1.id)
    assert endpoint.state == "terminated"
  end

  test "does not mark endpoint as terminated if survey terminated but there still are pending messages to push", %{server: server} do
    # 1 survey terminated
    survey1 = insert(:survey, state: "terminated")

    # 2000 responses
    respondent = insert(:respondent, survey: survey1)
    insert_list(2000, :response, respondent: respondent)

    # 1 endpoint with no pushed responses
    endpoint = insert_endpoint(survey1, uri: "http://localhost:#{server.port}/1.1", last_pushed_response_id: nil)

    # Allow endpoint server to receive anything
    server |> expect_success_always

    # Pusher runs
    run_pusher_without_logging()

    # Endpoint state remains enabled
    endpoint = Repo.get_by(FloipEndpoint, uri: endpoint.uri, survey_id: survey1.id)
    assert endpoint.state == "enabled"
  end

  # Note: this test leaks. I had to create a response to ensure that
  # the endpoint is ignored due to being terminated and not because
  # the collection of responses is empty.
  # What I want to avoid with this test is unnecesarily loading endpoints
  # for terminated surveys to which we already pushed all responses.
  test "ignores terminated endpoints", %{server: server} do
    # 1 survey terminated
    survey1 = insert(:survey, state: "terminated")

    # 1 response
    insert_response(survey1)

    # 1 terminated endpoint
    insert_endpoint(survey1, uri: "http://localhost:#{server.port}/1.1", state: "terminated")

    # Pusher runs
    run_pusher_without_logging()

    # Endpoint server does not receive any POST
  end

  test "sets auth token", %{server: server} do
    survey1 = insert(:survey, state: "running")
    insert_response(survey1)
    insert_endpoint(survey1, uri: "http://localhost:#{server.port}/1.1", auth_token: "IM_A_TOKEN")

    Bypass.expect_once server, "POST", "/1.1/flow-results/packages/#{survey1.floip_package_id}/responses", fn conn ->
      {"authorization", "IM_A_TOKEN"} = conn.req_headers |> List.keyfind("authorization", 0)
      Plug.Conn.resp(conn, 200, "")
    end

    run_pusher_without_logging()
  end
end
