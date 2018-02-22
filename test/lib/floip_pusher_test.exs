defmodule FloipPusherTest do
  use Ask.ModelCase
  alias Ask.{Repo, FloipPusher, FloipEndpoint}

  setup do
    server = Bypass.open(port: 1234)
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

  defp assert_last_response(survey, endpoint, response) do
    endpoint = Repo.get_by(FloipEndpoint, uri: endpoint.uri, survey_id: survey.id)
    assert endpoint.last_pushed_response_id == response.id
  end

  defp expect_push(server, endpoint_namespace, package_id) do
    Bypass.expect_once server, "POST", "/#{endpoint_namespace}/flow-results/packages/#{package_id}/responses", fn conn ->
      Plug.Conn.resp(conn, 200, "")
    end
    server
  end

  defp expect_success(server) do
    Bypass.expect server, fn conn ->
      Plug.Conn.resp(conn, 200, "")
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

    server |> expect_success

    # Run the pusher
    {:ok, _} = FloipPusher.start_link
    FloipPusher.poll

    # Verify that each endpoint ends up with the right last_response_id set
    assert_last_response(survey1, endpoint_1_survey_1, response_2_survey_1)
    assert_last_response(survey1, endpoint_2_survey_1, response_2_survey_1)
    assert_last_response(survey2, endpoint_1_survey_2, response_2_survey_2)
    assert_last_response(survey2, endpoint_2_survey_2, response_2_survey_2)
  end

  test "pushes to all endpoints that have new responses", %{server: server} do
    # 2 running surveys
    survey1 = insert(:survey, state: "running")
    survey2 = insert(:survey, state: "running")

    # 2 endpoints per survey
    insert_endpoint(survey1, uri: "http://localhost:1234/1.1")
    insert_endpoint(survey1, uri: "http://localhost:1234/2.1")
    insert_endpoint(survey2, uri: "http://localhost:1234/1.2")
    insert_endpoint(survey2, uri: "http://localhost:1234/2.2")

    # 2 responses per survey
    insert_response(survey1)
    insert_response(survey1)
    insert_response(survey2)
    insert_response(survey2)

    server
    |> expect_push("1.1", survey1.floip_package_id)
    |> expect_push("2.1", survey1.floip_package_id)
    |> expect_push("1.2", survey2.floip_package_id)
    |> expect_push("2.2", survey2.floip_package_id)

    # Run the pusher
    {:ok, _} = FloipPusher.start_link
    FloipPusher.poll
  end

  test "does not overwrite last_pushed_response_id if push fails" do
    # Create 2 surveys
    # Add 2 endpoints to each survey
    # Add 2 responses to each survey
    # Set up the mock to fail for one of the endpoints
    # Run poll
    # Verify that last_pushed_response_id hasn't changed for the failing endpoint
    # Verify that last_pushed_response_id has changed for succeeding endpoints
  end

  test "does not push to endpoints with no new responses" do
    # Create 2 surveys
    # Add 2 endpoints to each survey
    # Add 2 responses to each survey
    # On one of the endpoints, set last_response_id to the latest response in the survey
    # Run poll
    # Verify that the receiving mock gets one POST for each endpoint, except the one that already had the last response
  end

  test "does not send more than 1000 responses per run per endpoint" do
    # Create 1 survey
    # Add 1 endpoint to the survey
    # Add 2000 responses to the survey
    # Run poll
    # Verify that the receiving mock gets the first 1000 responses
  end

  test "increments endpoint retry counter if push fails" do
    # Create 1 survey
    # Add 1 endpoint to the survey
    # Add 2 responses to the survey
    # Configure receiving mock to fail
    # Run poll
    # Verify that the endpoint retry counter is now set at 1
  end

  test "resets endpoint retry counter if push succeeds" do
    # Create 1 survey
    # Add 1 endpoint to the survey, with retry counter == 8
    # Add 2 responses to the survey
    # Run poll
    # Verify that the endpoint retry counter is now set at 0
  end

  test "ignores endpoints with more than 10 retries because the receiving end is likely down" do
    # Create 2 suveys
    # Add 2 endpoints to each survey, one with 10 retries and one with 0 retries for each survey
    # Add 2 responses to each survey
    # Run poll
    # Verify that the receiving mock only gets posts for the 2 endpoints with 0 retries
  end
end