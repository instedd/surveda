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
  alias Ask.Runtime.{Broker, Flow, ReplyHelper, ChannelStatusServer, VerboiceChannel}
  alias Ask.{Repo, Survey, Respondent, RetryStat, SystemTime}
  require Ask.Runtime.ReplyHelper

  setup do
    {:ok, channel_status_server} = ChannelStatusServer.start_link
    {:ok, channel_status_server: channel_status_server}
  end

  @tag :time_mock
  test "SMS mode with user interactions and retries histogram output" do
    [survey, _group, test_channel, _respondent, phone_number] = create_running_survey_with_channel_and_respondent()
    survey = survey |> Survey.changeset(%{sms_retry_configuration: "2h", fallback_delay: "3h"}) |> Repo.update!
    sequence_mode = ["sms"]
    expected_histogram_flow = [%{delay: 0, type: "sms"}, %{delay: 2, label: "2h", type: "sms"}, %{delay: 3, label: "3h", type: "end"}]

    {:ok, now, _} = DateTime.from_iso8601("2019-12-23T09:00:00Z")
    mock_time(now)

    stats = RetryStat.stats(%{survey_id: survey.id})
    assert %{actives: [], flow: expected_histogram_flow} == Ask.RetriesHistogram.mode_sequence_histogram(survey, stats, sequence_mode, now)

    # First poll, activate the respondent
    Broker.handle_info(:poll, nil)
    assert_received [:setup, ^test_channel, respondent = %Respondent{sanitized_phone_number: ^phone_number}, token]
    assert_received [:ask, ^test_channel, ^respondent, ^token, ReplyHelper.simple("Do you smoke?", "Do you smoke? Reply 1 for YES, 2 for NO")]

    # The respondent should be in the first column
    stats = RetryStat.stats(%{survey_id: survey.id})
    assert %{actives: [%{hour: 0, respondents: 1}], flow: expected_histogram_flow} == Ask.RetriesHistogram.mode_sequence_histogram(survey, stats, sequence_mode, now)

    respondent = Repo.get!(Respondent, respondent.id)

    # set expectations
    {:ok, expected_timeout, _} = DateTime.from_iso8601("2019-12-23T11:00:00Z")
    expected_retry_time = "2019122311"
    expected_attempts = 1

    # Since the respondent was queued, there must be a RetryStat
    assert 1 == stats |> RetryStat.count(%{attempt: 1, retry_time: expected_retry_time, ivr_active: false, mode: sequence_mode})
    assert "queued" == respondent.disposition
    assert expected_attempts == respondent.stats.attempts["sms"]
    assert expected_timeout == respondent.timeout_at

    # An hour passed
    {:ok, now, _} = DateTime.from_iso8601("2019-12-23T10:00:00Z")
    mock_time(now)

    # The respondent should be in the 2nd column
    stats = RetryStat.stats(%{survey_id: survey.id})
    assert %{actives: [%{hour: 1, respondents: 1}], flow: expected_histogram_flow} == Ask.RetriesHistogram.mode_sequence_histogram(survey, stats, sequence_mode, now)

    # respondent responses the first question
    reply = Broker.sync_step(respondent, Flow.Message.reply("Yes"), "sms")
    # broker sends second question
    assert {:reply, ReplyHelper.simple("Do you exercise", "Do you exercise? Reply 1 for YES, 2 for NO")} = reply

    # the respondent should return to the first column
    stats = RetryStat.stats(%{survey_id: survey.id})
    assert %{actives: [%{hour: 0, respondents: 1}], flow: expected_histogram_flow} == Ask.RetriesHistogram.mode_sequence_histogram(survey, stats, sequence_mode, now)

    # set expectations
    past_retry_time = expected_retry_time
    expected_retry_time = "2019122312"
    {:ok, expected_timeout, _} = DateTime.from_iso8601("2019-12-23T12:00:00Z")

    respondent = Repo.get!(Respondent, respondent.id)

    # Since the respondent was re-contacted, the RetryStat must be updated
    assert "started" == respondent.disposition
    assert expected_attempts == respondent.stats.attempts["sms"]
    assert expected_timeout == respondent.timeout_at

    assert 0 == stats |> RetryStat.count(%{attempt: expected_attempts, retry_time: past_retry_time, ivr_active: false, mode: sequence_mode})
    assert 1 == stats |> RetryStat.count(%{attempt: expected_attempts, retry_time: expected_retry_time, ivr_active: false, mode: sequence_mode})

    # Two hour passed
    {:ok, now, _} = DateTime.from_iso8601("2019-12-23T12:00:00Z")
    mock_time(now)

    # The respondent should be in the 2nd column again
    stats = RetryStat.stats(%{survey_id: survey.id})
    assert %{actives: [%{hour: 1, respondents: 1}], flow: expected_histogram_flow} == Ask.RetriesHistogram.mode_sequence_histogram(survey, stats, sequence_mode, now)

    # Second poll, it should retry the second question
    Broker.handle_info(:poll, nil)
    refute_received [:setup, _, _, _, _]
    assert_received [:ask, ^test_channel, %Respondent{sanitized_phone_number: ^phone_number}, _token, ReplyHelper.simple("Do you exercise", "Do you exercise? Reply 1 for YES, 2 for NO")]

    # The respondent should be in the 3rd column
    stats = RetryStat.stats(%{survey_id: survey.id})
    assert %{actives: [%{hour: 2, respondents: 1}], flow: expected_histogram_flow} == Ask.RetriesHistogram.mode_sequence_histogram(survey, stats, sequence_mode, now)

    # set expectations
    past_retry_time = expected_retry_time
    expected_retry_time = "2019122315"
    {:ok, expected_timeout, _} = DateTime.from_iso8601("2019-12-23T15:00:00Z")
    past_attempts = expected_attempts
    expected_attempts = 2

    # Respondent should have been moved from first attempt to second attempt in RetryStat
    respondent = Repo.get!(Respondent, respondent.id)
    assert expected_attempts == respondent.stats.attempts["sms"]
    assert expected_timeout == respondent.timeout_at
    assert 0 == stats |> RetryStat.count(%{attempt: past_attempts, retry_time: past_retry_time, ivr_active: false, mode: sequence_mode})
    assert 1 == stats |> RetryStat.count(%{attempt: expected_attempts, retry_time: expected_retry_time, ivr_active: false, mode: sequence_mode})

    # An hour passed
    {:ok, now, _} = DateTime.from_iso8601("2019-12-23T13:00:00Z")
    mock_time(now)

    # The respondent should be in the 4th column
    stats = RetryStat.stats(%{survey_id: survey.id})
    assert %{actives: [%{hour: 3, respondents: 1}], flow: expected_histogram_flow} == Ask.RetriesHistogram.mode_sequence_histogram(survey, stats, sequence_mode, now)

    # respondent responses the first question
    reply = Broker.sync_step(respondent, Flow.Message.reply("Yes"), "sms")
    # broker sends third question
    assert {:reply, ReplyHelper.simple("Which is the second perfect number?", "Which is the second perfect number??")} = reply

    # The respondent should return to the 3rd column
    stats = RetryStat.stats(%{survey_id: survey.id})
    assert %{actives: [%{hour: 2, respondents: 1}], flow: expected_histogram_flow} == Ask.RetriesHistogram.mode_sequence_histogram(survey, stats, sequence_mode, now)

    # set expectations
    past_retry_time = expected_retry_time
    expected_retry_time = "2019122316"
    {:ok, expected_timeout, _} = DateTime.from_iso8601("2019-12-23T16:00:00Z")

    respondent = Repo.get!(Respondent, respondent.id)

    # Since the respondent was re-contacted, the RetryStat must be updated
    assert "started" == respondent.disposition
    assert expected_attempts == respondent.stats.attempts["sms"]
    assert expected_timeout == respondent.timeout_at

    assert 0 == stats |> RetryStat.count(%{attempt: expected_attempts, retry_time: past_retry_time, ivr_active: false, mode: sequence_mode})
    assert 1 == stats |> RetryStat.count(%{attempt: expected_attempts, retry_time: expected_retry_time, ivr_active: false, mode: sequence_mode})

    # Three hour passed
    {:ok, now, _} = DateTime.from_iso8601("2019-12-23T16:00:00Z")
    mock_time(now)

    # The respondent should be in the 6th column
    stats = RetryStat.stats(%{survey_id: survey.id})
    assert %{actives: [%{hour: 5, respondents: 1}], flow: expected_histogram_flow} == Ask.RetriesHistogram.mode_sequence_histogram(survey, stats, sequence_mode, now)

    # Third poll, it should stall the respondent
    Broker.handle_info(:poll, nil)
    refute_received [:setup, _, _, _, _]
    refute_received [:ask, _, _, _]

    # Respondent should have been stalled and removed from the Histogram
    stats = RetryStat.stats(%{survey_id: survey.id})

    assert [] == stats
    assert 0 == stats |> RetryStat.count(%{attempt: expected_attempts, retry_time: expected_retry_time, ivr_active: false, mode: sequence_mode})
    assert %{actives: [], flow: expected_histogram_flow} == Ask.RetriesHistogram.mode_sequence_histogram(survey, stats, sequence_mode, now)

    respondent = Repo.get!(Respondent, respondent.id)

    assert "stalled" == respondent.state
    assert expected_attempts == respondent.stats.attempts["sms"]
    refute respondent.timeout_at
  end

  @tag :time_mock
  test "IVR mode with no user interaction" do
    %{expected_histogram: expected_histogram, assert_histogram: assert_histogram, call_failed: call_failed} = initialize_simple_ivr()

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

    expected_histogram.([%{hour: 1, respondents: 1}])
    |> assert_histogram.("the respondent should be in the 2nd column")

    # An hour passed
    time_passes(hours: 1)

    # 2nd poll, retry the respondent
    broker_poll()

    expected_histogram.([%{hour: 2, respondents: 1}])
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

  defp initialize_survey(mode, survey_configuration) do
    [survey, _group, _test_channel, respondent, _phone_number] = create_running_survey_with_channel_and_respondent(@dummy_steps, mode)
    survey = survey |> Survey.changeset(survey_configuration) |> Repo.update!
    %{survey: survey, respondent: respondent}
  end

  defp initialize_simple_ivr() do
    %{survey: survey, respondent: respondent} = initialize_survey("ivr", %{ivr_retry_configuration: "2h"})

    expected_histogram = fn actives -> %{actives: actives, flow: [%{delay: 0, type: "ivr"}, %{delay: 2, label: "2h", type: "ivr"}]} end
    assert_histogram = fn (histogram, message) -> assert_histogram(survey, ["ivr"], histogram, message) end
    call_failed = fn () -> call_failed(build_conn(), respondent.id) end

    %{survey: survey, respondent: respondent, expected_histogram: expected_histogram, assert_histogram: assert_histogram, call_failed: call_failed}
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

  defp call_failed(conn, respondent_id), do:
    VerboiceChannel.callback(conn, %{"path" => ["status", respondent_id, "token"], "CallStatus" => "failed", "CallDuration" => "10", "CallStatusReason" => "some random reason", "CallStatusCode" => "42"})

end
