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
  @moduletag :time_mock

  setup do
    {:ok, _} = ChannelStatusServer.start_link
    :ok
  end

  describe "IVR -> 2h -> IVR" do
    setup context do
      config = %{survey_retry_config: %{ivr_retry_configuration: "2h"}, retries: [2], fallback_delay: 0}
      init_ivr(config, context)
    end

    test "no user interaction", %{expected_histogram: expected_histogram, assert_histogram: assert_histogram,
    call_failed: call_failed, histogram_hour: histogram_hour} do
      set_current_time("2019-12-23T09:00:00Z")

      expected_histogram.([])
      |> assert_histogram.("the histogram should be empty")

      # 1st poll, activate the respondent
      broker_poll()

      expected_histogram.([%{hour: 0, respondents: 1}])
      |> assert_histogram.("the respondent should be in the 1st column")

      # The call fails so the respondent is no longer active
      call_failed.()

      time_passes(hours: 1)

      expected_histogram.([%{hour: histogram_hour.(%{attempt: 1, hours_after: 1}), respondents: 1}])
      |> assert_histogram.("the respondent should be in the 2nd column")

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

    test "ended call remains in the active column until time passes", %{expected_histogram: expected_histogram, assert_histogram: assert_histogram,
    call_failed: call_failed, histogram_hour: histogram_hour} do
      set_current_time("2019-12-23T09:00:00Z")

      # 1st poll, activate the respondent
      broker_poll()

      expected_histogram.([%{hour: 0, respondents: 1}])
      |> assert_histogram.("the respondent should be in the 1st column")

      # The call fails so the respondent is no longer active
      call_failed.()

      expected_histogram.([%{hour: 0, respondents: 1}])
      |> assert_histogram.("the respondent should be still in the 1st column until an hour passes")

      time_passes(hours: 1)

      expected_histogram.([%{hour: histogram_hour.(%{attempt: 1, hours_after: 1}), respondents: 1}])
      |> assert_histogram.("the respondent should now be in the first attempt - first hour column")
    end

    test "respondent remains active until the call fails", %{expected_histogram: expected_histogram, assert_histogram: assert_histogram,
    call_failed: call_failed, histogram_hour: histogram_hour} do
      set_current_time("2019-12-23T09:00:00Z")

      # 1st poll, activate the respondent
      broker_poll()

      time_passes(hours: 10)

      expected_histogram.([%{hour: 0, respondents: 1}])
      |> assert_histogram.("the respondent should be in the 1st column")

      # The call fails so the respondent is no longer active
      call_failed.()

      time_passes(hours: 1)

      expected_histogram.([%{hour: histogram_hour.(%{attempt: 1, hours_after: 1}), respondents: 1}])
      |> assert_histogram.("the respondent should be in the first attempt - first hour column")
    end

    test "respondent stays in the last inactive column of its current attempt until they are retried", %{expected_histogram: expected_histogram, assert_histogram: assert_histogram,
    call_failed: call_failed, histogram_hour: histogram_hour} do
      set_current_time("2019-12-23T09:00:00Z")

      # 1st poll, activate the respondent
      broker_poll()

      # The call fails so the respondent is no longer active
      call_failed.()

      time_passes(hours: 1)

      expected_histogram.([%{hour: histogram_hour.(%{attempt: 1, hours_after: 1}), respondents: 1}])
      |> assert_histogram.("the respondent should be in the first attempt - first hour column")

      time_passes(hours: 10)

      expected_histogram.([%{hour: histogram_hour.(%{attempt: 1, hours_after: 1}), respondents: 1}])
      |> assert_histogram.("the respondent should be still in the first attempt - first hour column")

      # 2nd poll, retry the respondent
      broker_poll()

      expected_histogram.([%{hour: histogram_hour.(%{attempt: 2}), respondents: 1}])
      |> assert_histogram.("The respondent should be in the second attempt active column")
    end
  end

  describe "SMS -> 2h -> SMS -> 3h" do
    setup context do
      conf = %{survey_retry_config: %{sms_retry_configuration: "2h", fallback_delay: "3h"}, retries: [2], fallback_delay: 3}
      init_sms(conf, context)
    end

    test "user interactions and stalled-respondent ending", %{expected_histogram: expected_histogram, assert_histogram: assert_histogram,
    histogram_hour: histogram_hour, respondent_reply: respondent_reply} do
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

      expected_histogram.([%{hour: histogram_hour.(%{attempt: 2, hours_after: 1}), respondents: 1}])
      |> assert_histogram.("the respondent should be in the the second attempt - first hour column")

      # respondent responses the second question
      respondent_reply.("Yes")

      expected_histogram.([%{hour: histogram_hour.(%{attempt: 2}), respondents: 1}])
      |> assert_histogram.("the respondent should return to the second attempt active column")

      time_passes(hours: 2)

      expected_histogram.([%{hour: histogram_hour.(%{attempt: 2, hours_after: 2}), respondents: 1}])
      |> assert_histogram.("the respondent should be in the second attempt - first hour column again")

      time_passes(hours: 1)

      # Third poll, it should stall the respondent
      broker_poll()

      # Respondent should have been stalled and removed from the Histogram
      expected_histogram.([])
      |> assert_histogram.("Respondent should have been stalled and removed from the Histogram")
    end
  end

  describe "Mobileweb -> 2h -> Mobileweb -> 3h" do
    setup context do
      config = %{survey_retry_config: %{mobileweb_retry_configuration: "2h", fallback_delay: "3h"}, retries: [2], fallback_delay: 3}
      init_mobileweb(config, context)
    end

    test "no user interaction", %{expected_histogram: expected_histogram, assert_histogram: assert_histogram,
      histogram_hour: histogram_hour} do
      set_current_time("2019-12-23T09:00:00Z")

      expected_histogram.([])
      |> assert_histogram.("the histogram should be empty")

      # 1st poll, activate the respondent
      broker_poll()

      expected_histogram.([%{hour: 0, respondents: 1}])
      |> assert_histogram.("the respondent should be in the 1st column")

      time_passes(hours: 1)

      expected_histogram.([%{hour: histogram_hour.(%{attempt: 1, hours_after: 1}), respondents: 1}])
      |> assert_histogram.("the respondent should be in the first attempt - first hour column")

      time_passes(hours: 1)

      # 2nd poll, retry the respondent
      broker_poll()

      expected_histogram.([%{hour: histogram_hour.(%{attempt: 2}), respondents: 1}])
      |> assert_histogram.("the respondent should be in the the second attempt active column")

      time_passes(hours: 2)

      expected_histogram.([%{hour: histogram_hour.(%{attempt: 2, hours_after: 2}), respondents: 1}])
      |> assert_histogram.("the respondent should be in the second attempt - second hour column")

      time_passes(hours: 1)

      # 3rd and last poll
      broker_poll()

      # As the respondent had no more retries left, the histogram should be empty
      expected_histogram.([])
      |> assert_histogram.("the histogram should be empty")

    end
  end

  defp assert_histogram(survey, sequence_mode, expected_histogram, message) do
    stats = RetryStat.stats(%{survey_id: survey.id})
    actual_histogram = Ask.RetriesHistogram.mode_sequence_histogram(survey, stats, sequence_mode, SystemTime.time.now)
    assert expected_histogram == actual_histogram, message
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

  defp init_mode(mode, %{survey_retry_config: mode_retry_config, retries: retries, fallback_delay: fallback_delay}) do
    %{survey: survey, respondent: respondent} = initialize_survey(mode, mode_retry_config)
    %{histogram_flow: expected_histogram_flow, histogram_hour: histogram_hour} = configure_retries_and_fallback(mode, retries, fallback_delay)

    expected_histogram = fn actives -> %{actives: actives, flow: expected_histogram_flow} end
    assert_histogram = fn (histogram, message) -> assert_histogram(survey, [mode], histogram, message) end

    %{survey: survey, respondent: respondent, expected_histogram: expected_histogram, assert_histogram: assert_histogram, histogram_hour: histogram_hour}
  end

  defp init_ivr(config, _context) do
    %{respondent: respondent} = context = init_mode("ivr", config)
    call_failed = fn () -> call_failed(build_conn(), respondent.id) end
    {:ok, Map.put(context, :call_failed, call_failed)}
  end

  defp init_sms(config, _context) do
    %{respondent: respondent} = context = init_mode("sms", config)
    respondent_reply = fn reply -> respondent_reply(respondent.id, reply) end
    {:ok, Map.put(context, :respondent_reply, respondent_reply)}
  end

  defp init_mobileweb(config, _context) do
    context = init_mode("mobileweb", config)
    {:ok, context}
  end

  defp call_failed(conn, respondent_id), do:
    VerboiceChannel.callback(conn, %{"path" => ["status", respondent_id, "token"], "CallStatus" => "failed", "CallDuration" => "10", "CallStatusReason" => "some random reason", "CallStatusCode" => "42"})

  defp configure_retries_and_fallback(type, retries_hours, fallback_delay_hours) when type in ["sms", "mobileweb"] do
    flow = base_flow(type, retries_hours)
           |> append_last_contacting_slot("end", fallback_delay_hours)

    %{histogram_flow: flow, histogram_hour: fn config -> histogram_hour(flow, config) end}
  end

  defp configure_retries_and_fallback("ivr" = type, retries_hours, _fallback_delay_hours) do
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
