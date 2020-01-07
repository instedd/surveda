defmodule Ask.Runtime.RetriesHistogramTest do
  import Ecto
  import Ecto.Changeset
  import Ecto.Query
  import Ask.Factory
  use Ask.ConnCase
  use Timex
  use Ask.DummySteps
  use Ask.MockTime
  use Ask.TestHelpers
  alias Ask.Runtime.{Broker, Flow, ChannelStatusServer, VerboiceChannel}
  alias Ask.{Repo, Survey, Respondent, RetryStat, SystemTime}
  require Ask.Runtime.ReplyHelper

  setup do
    {:ok, channel_status_server} = ChannelStatusServer.start_link
    {:ok, channel_status_server: channel_status_server}
  end

  @tag :time_mock
  test "SMS mode with user interactions and stalled-respondent ending" do
    [survey, _group, _test_channel, respondent, _phone_number] = create_running_survey_with_channel_and_respondent()
    survey = survey |> Survey.changeset(%{sms_retry_configuration: "2h", fallback_delay: "3h"}) |> Repo.update!
    %{histogram_flow: expected_histogram_flow, histogram_hour: histogram_hour} = configure_retries_and_fallback("sms", [2], 3)

    expected_histogram = fn actives -> %{actives: actives, flow: expected_histogram_flow} end
    assert_histogram = fn (histogram, message) -> assert_histogram(survey, ["sms"], histogram, message) end
    respondent_reply = fn reply -> respondent_reply(respondent.id, reply) end

    set_current_time("2019-12-23T09:00:00Z")

    expected_histogram.([])
    |> assert_histogram.("Histogram should be empty since respondent is still in state = pending")

    # First poll, activate the respondent
    broker_poll()

    expected_histogram.([%{hour: 0, respondents: 1}])
    |> assert_histogram.("The respondent should be in the first column")

    time_passes(hours: 1)

    expected_histogram.([%{hour: histogram_hour.(%{attempt: 1, hours_after: 1}), respondents: 1}])
    |> assert_histogram.("the respondent should be in the first attempt - first hour column")

    # respondent responses the first question
    respondent_reply.("Yes")

    expected_histogram.([%{hour: histogram_hour.(%{attempt: 1}), respondents: 1}])
    |> assert_histogram.("the respondent should return to the first attempt active column")

    time_passes(hours: 2)

    # Second poll, it should retry the second question
    broker_poll()

    expected_histogram.([%{hour: histogram_hour.(%{attempt: 2}), respondents: 1}])
    |> assert_histogram.("The respondent should be in the second attempt active column")

    time_passes(hours: 1)

    # The respondent should be in the 4th column
    expected_histogram.([%{hour: histogram_hour.(%{attempt: 2, hours_after: 1}), respondents: 1}])
    |> assert_histogram.("the respondent should be in the the second attempt - first hour column")

    # respondent responses the second question
    respondent_reply.("Yes")

    expected_histogram.([%{hour: histogram_hour.(%{attempt: 2}), respondents: 1}])
    |> assert_histogram.("the respondent should return to the second attempt active column")

    # Three hour passed (fallback-delay)
    time_passes(hours: 3)

    # Third poll, it should stall the respondent
    broker_poll()

    # Respondent should have been stalled and removed from the Histogram
    expected_histogram.([])
    |> assert_histogram.("Respondent should have been stalled and removed from the Histogram")
  end

  @tag :time_mock
  test "IVR mode with no user interaction" do
    %{expected_histogram: expected_histogram, assert_histogram: assert_histogram,
      call_failed: call_failed, histogram_hour: histogram_hour} = initialize_simple_ivr()

    set_current_time("2019-12-23T09:00:00Z")

    expected_histogram.([])
    |> assert_histogram.("the histogram should be empty")

    # 1st poll, activate the respondent
    broker_poll()

    expected_histogram.([%{hour: 0, respondents: 1}])
    |> assert_histogram.("the respondent should be in the 1st column")

    # The call fails so the respondent is no longer active
    call_failed.()

    # An hour passed
    time_passes(hours: 1)

    expected_histogram.([%{hour: histogram_hour.(%{attempt: 1, hours_after: 1}), respondents: 1}])
    |> assert_histogram.("the respondent should be in the 2nd column")

    # An hour passed
    time_passes(hours: 1)

    # 2nd poll, retry the respondent
    broker_poll()

    expected_histogram.([%{hour: histogram_hour.(%{attempt: 1, hours_after: 2}), respondents: 1}])
    |> assert_histogram.("the respondent should be in the 3rd column")

    # The call fails so the respondent is no longer active
    call_failed.()

    # As the respondent had no more retries left, the histogram should be empty
    expected_histogram.([])
    |> assert_histogram.("the histogram should be empty")
  end

  @tag :time_mock
  test "ended call remains in the active column until time passes" do
    %{expected_histogram: expected_histogram, assert_histogram: assert_histogram, call_failed: call_failed} = initialize_simple_ivr()

    set_current_time("2019-12-23T09:00:00Z")

    # 1st poll, activate the respondent
    broker_poll()

    expected_histogram.([%{hour: 0, respondents: 1}])
    |> assert_histogram.("the respondent should be in the 1st column")

    # The call fails so the respondent is no longer active
    call_failed.()

    # The respondent should be still in the first column since
    expected_histogram.([%{hour: 0, respondents: 1}])
    |> assert_histogram.("the respondent should be still in the 1st column")

    # An hour passed
    time_passes(hours: 1)

    expected_histogram.([%{hour: 1, respondents: 1}])
    |> assert_histogram.("the respondent should now be in the 2nd column")
  end

  @tag :time_mock
  test "respondent remains active until the call fails" do
    %{expected_histogram: expected_histogram, assert_histogram: assert_histogram, call_failed: call_failed} = initialize_simple_ivr()

    set_current_time("2019-12-23T09:00:00Z")

    # 1st poll, activate the respondent
    broker_poll()

    # Several hours passed
    time_passes(hours: 10)

    expected_histogram.([%{hour: 0, respondents: 1}])
    |> assert_histogram.("the respondent should be in the 1st column")

    # The call fails so the respondent is no longer active
    call_failed.()

    # An hour passed
    time_passes(hours: 1)

    expected_histogram.([%{hour: 1, respondents: 1}])
    |> assert_histogram.("the respondent should be in the 2nd column")
  end

  @tag :time_mock
  test "respondent stays in the last inactive column of its current attempt until they are retried" do
    %{expected_histogram: expected_histogram, assert_histogram: assert_histogram, call_failed: call_failed} = initialize_simple_ivr()

    set_current_time("2019-12-23T09:00:00Z")

    # 1st poll, activate the respondent
    broker_poll()

    # The call fails so the respondent is no longer active
    call_failed.()

    # An hour passed
    time_passes(hours: 1)

    expected_histogram.([%{hour: 1, respondents: 1}])
    |> assert_histogram.("the respondent should be in the 2nd column")

    # Several hours passed
    time_passes(hours: 10)

    expected_histogram.([%{hour: 1, respondents: 1}])
    |> assert_histogram.("the respondent should be still in the 2nd column")

    # 2nd poll, retry the respondent
    broker_poll()

    expected_histogram.([%{hour: 2, respondents: 1}])
    |> assert_histogram.("the respondent should now be in the 3rd column")
  end

  @tag :time_mock
  test "Mobileweb mode with no user interaction" do
    [survey, _group, _test_channel, _respondent, _phone_number] = create_running_survey_with_channel_and_respondent(@dummy_steps, "mobileweb")
    survey = survey |> Survey.changeset(%{ivr_retry_configuration: "2h", fallback_delay: "3h"}) |> Repo.update!

    expected_histogram = fn actives -> %{actives: actives, flow: [%{delay: 0, type: "mobileweb"}, %{delay: 3, label: "3h", type: "end"}]} end
    assert_histogram = fn (histogram, message) -> assert_histogram(survey, ["mobileweb"], histogram, message) end

    set_current_time("2019-12-23T09:00:00Z")

    expected_histogram.([])
    |> assert_histogram.("the histogram should be empty")

    # 1st poll, activate the respondent
    broker_poll()

    expected_histogram.([%{hour: 0, respondents: 1}])
    |> assert_histogram.("the respondent should be in the 1st column")

    # An hour passed
    time_passes(hours: 1)

    expected_histogram.([%{hour: 1, respondents: 1}])
    |> assert_histogram.("the respondent should be in the 2nd column")

    # An hour passed
    time_passes(hours: 1)

    # 2nd poll, retry the respondent
    broker_poll()

    expected_histogram.([%{hour: 2, respondents: 1}])
    |> assert_histogram.("the respondent should be in the 3rd column")

    # An hour passed
    time_passes(hours: 1)

    expected_histogram.([%{hour: 3, respondents: 1}])
    |> assert_histogram.("the respondent should be in the 4th column")

    # An hour passed
    time_passes(hours: 1)

    # 3rd and last poll
    broker_poll()

    # As the respondent had no more retries left, the histogram should be empty
    expected_histogram.([])
    |> assert_histogram.("the histogram should be empty")

  end

  defp assert_histogram(survey, sequence_mode, histogram, message) do
    stats = RetryStat.stats(%{survey_id: survey.id})
    assert histogram == Ask.RetriesHistogram.mode_sequence_histogram(survey, stats, sequence_mode, SystemTime.time.now), message
  end

  defp set_current_time(time) do
    {:ok, now, _} = DateTime.from_iso8601(time)
    mock_time(now)
  end

  defp time_passes(diff), do:
    SystemTime.time.now
    |> Timex.shift(diff)
    |> mock_time

  defp broker_poll(), do: Broker.handle_info(:poll, nil)

  defp initialize_survey(mode, survey_configuration) do
    [survey, _group, _test_channel, respondent, _phone_number] = create_running_survey_with_channel_and_respondent(@dummy_steps, mode)
    survey = survey |> Survey.changeset(survey_configuration) |> Repo.update!
    %{survey: survey, respondent: respondent}
  end

  defp initialize_simple_ivr() do
    %{survey: survey, respondent: respondent} = initialize_survey("ivr", %{ivr_retry_configuration: "2h"})
    %{histogram_flow: expected_histogram_flow, histogram_hour: histogram_hour} = configure_retries_and_fallback("ivr", [2])
    expected_histogram = fn actives -> %{actives: actives, flow: expected_histogram_flow} end
    assert_histogram = fn (histogram, message) -> assert_histogram(survey, ["ivr"], histogram, message) end
    call_failed = fn () -> call_failed(build_conn(), respondent.id) end

    %{survey: survey, respondent: respondent, expected_histogram: expected_histogram, assert_histogram: assert_histogram, call_failed: call_failed, histogram_hour: histogram_hour}
  end

  defp call_failed(conn, respondent_id), do:
    VerboiceChannel.callback(conn, %{"path" => ["status", respondent_id, "token"], "CallStatus" => "failed", "CallDuration" => "10", "CallStatusReason" => "some random reason", "CallStatusCode" => "42"})

  defp configure_retries_and_fallback("sms" = type, retries_hours, fallback_delay_hours) do
    flow = base_flow(type, retries_hours)
           |> append_last_contacting_slot("end", fallback_delay_hours)

    %{histogram_flow: flow, histogram_hour: fn config -> histogram_hour(flow, config) end}
  end

  defp configure_retries_and_fallback("ivr" = type, retries_hours) do
    flow = base_flow(type, retries_hours)
    %{histogram_flow: flow, histogram_hour: fn config -> histogram_hour(flow, config) end}
  end

  defp base_flow(type, retries_hours), do:
    retries_hours
    |> Enum.reduce([%{delay: 0, type: type}], fn x, accum -> append_last_contacting_slot(accum, type, x) end)

  defp append_last_contacting_slot(list, type, delay), do: list ++ [contacting_slot(type, delay)]


  # Calculates the hour in the histogram that represents the given attempt and the hours that passed from this one
  # If no :hours_after, 0 is considered
  defp histogram_hour(flow, %{attempt: attempt, hours_after: hours_after_attempt}) do
    base_hours = flow
                 |> Enum.slice(0, attempt)
                 |> Enum.map(fn %{delay: delay} -> delay end)
                 |> Enum.sum

    base_hours + hours_after_attempt
  end

  defp histogram_hour(flow, %{attempt: _attempt} = map), do: histogram_hour(flow, Map.put(map, :hours_after, 0))

  defp contacting_slot(type, delay), do: %{delay: delay, label: "#{delay}h", type: type}

  defp respondent_reply(respondent_id, reply_message) do
    respondent = Repo.get!(Respondent, respondent_id)
    Broker.sync_step(respondent, Flow.Message.reply(reply_message), "sms")
  end
end
