defmodule Ask.Runtime.RetriesHistogramTest do
  import Ecto
  import Ecto.Changeset
  import Ecto.Query
  import Ask.Factory
  use AskWeb.ConnCase
  use Timex
  use Ask.MockTime
  use Ask.TestHelpers

  alias Ask.Runtime.{
    Survey,
    SurveyBroker,
    Flow,
    ChannelStatusServer,
    VerboiceChannel,
    RetriesHistogram,
    Session
  }

  alias Ask.{Repo, Survey, Respondent, Stats}
  require Ask.Runtime.ReplyHelper
  alias Ask.{RespondentGroupChannel, TestChannel, Schedule}
  @moduletag :time_mock

  setup do
    {:ok, _} = ChannelStatusServer.start_link()
    :ok
  end

  describe "IVR -> 2h -> IVR with dummy steps" do
    setup context do
      config =
        TestConfiguration.base_config()
        |> TestConfiguration.with_survey_retries_config(%{ivr_retry_configuration: "2h"})
        |> TestConfiguration.with_retries([2])

      init_ivr(config, context)
    end

    test "no user interaction", %{
      expected_histogram: expected_histogram,
      assert_histogram: assert_histogram,
      call_failed: call_failed,
      histogram_hour: histogram_hour
    } do
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

      expected_histogram.([
        %{hour: histogram_hour.(%{attempt: 1, hours_after: 1}), respondents: 1}
      ])
      |> assert_histogram.("the respondent should be in the 2nd column")

      time_passes(hours: 1)

      # 2nd poll, retry the respondent
      broker_poll()

      expected_histogram.([
        %{hour: histogram_hour.(%{attempt: 1, hours_after: 2}), respondents: 1}
      ])
      |> assert_histogram.("the respondent should be in the 3rd column")

      # The call fails so the respondent is no longer active
      call_failed.()

      # As the respondent had no more retries left, the histogram should be empty
      expected_histogram.([])
      |> assert_histogram.("the histogram should be empty")
    end

    test "ended call remains in the active column until time passes", %{
      expected_histogram: expected_histogram,
      assert_histogram: assert_histogram,
      call_failed: call_failed,
      histogram_hour: histogram_hour
    } do
      set_current_time("2019-12-23T09:00:00Z")

      # 1st poll, activate the respondent
      broker_poll()

      expected_histogram.([%{hour: 0, respondents: 1}])
      |> assert_histogram.("the respondent should be in the 1st column")

      # The call fails so the respondent is no longer active
      call_failed.()

      expected_histogram.([%{hour: 0, respondents: 1}])
      |> assert_histogram.(
        "the respondent should be still in the 1st column until an hour passes"
      )

      time_passes(hours: 1)

      expected_histogram.([
        %{hour: histogram_hour.(%{attempt: 1, hours_after: 1}), respondents: 1}
      ])
      |> assert_histogram.(
        "the respondent should now be in the first attempt - first hour column"
      )
    end

    test "respondent remains active until the call fails", %{
      expected_histogram: expected_histogram,
      assert_histogram: assert_histogram,
      call_failed: call_failed,
      histogram_hour: histogram_hour
    } do
      set_current_time("2019-12-23T09:00:00Z")

      # 1st poll, activate the respondent
      broker_poll()

      time_passes(hours: 10)

      expected_histogram.([%{hour: 0, respondents: 1}])
      |> assert_histogram.("the respondent should be in the 1st column")

      # The call fails so the respondent is no longer active
      call_failed.()

      time_passes(hours: 1)

      expected_histogram.([
        %{hour: histogram_hour.(%{attempt: 1, hours_after: 1}), respondents: 1}
      ])
      |> assert_histogram.("the respondent should be in the first attempt - first hour column")
    end

    test "respondent stays in the last inactive column of its current attempt until they are retried",
         %{
           expected_histogram: expected_histogram,
           assert_histogram: assert_histogram,
           call_failed: call_failed,
           histogram_hour: histogram_hour
         } do
      set_current_time("2019-12-23T09:00:00Z")

      # 1st poll, activate the respondent
      broker_poll()

      # The call fails so the respondent is no longer active
      call_failed.()

      time_passes(hours: 1)

      expected_histogram.([
        %{hour: histogram_hour.(%{attempt: 1, hours_after: 1}), respondents: 1}
      ])
      |> assert_histogram.("the respondent should be in the first attempt - first hour column")

      time_passes(hours: 10)

      expected_histogram.([
        %{hour: histogram_hour.(%{attempt: 1, hours_after: 1}), respondents: 1}
      ])
      |> assert_histogram.(
        "the respondent should be still in the first attempt - first hour column"
      )

      # 2nd poll, retry the respondent
      broker_poll()

      expected_histogram.([%{hour: histogram_hour.(%{attempt: 2}), respondents: 1}])
      |> assert_histogram.("The respondent should be in the second attempt active column")
    end

    test "respondent replies and ends survey", %{
      expected_histogram: expected_histogram,
      assert_histogram: assert_histogram,
      histogram_hour: histogram_hour,
      respondent_reply: respondent_reply
    } do
      assert_respondent_active_in_first_attempt = fn ->
        expected_histogram.([%{hour: histogram_hour.(%{attempt: 1}), respondents: 1}])
        |> assert_histogram.("the respondent should be in the first attempt active column")
      end

      set_current_time("2019-12-23T09:00:00Z")

      # 1st poll, activate the respondent
      broker_poll()
      assert_respondent_active_in_first_attempt.()

      # "Do you smoke? Press 8 for YES, 9 for NO"
      {:reply, _, _} = respondent_reply.("8")
      assert_respondent_active_in_first_attempt.()

      # "Do you exercise? Press 1 for YES, 2 for NO"
      {:reply, _, _} = respondent_reply.("1")
      assert_respondent_active_in_first_attempt.()

      # "Which is the second perfect number"
      {:reply, _, _} = respondent_reply.("23")
      assert_respondent_active_in_first_attempt.()

      # "What's the number of this question?"
      {:end, _, _} = respondent_reply.("4")

      expected_histogram.([])
      |> assert_histogram.(
        "The respondent should have ended the survey, thus the histogram should be empty"
      )
    end
  end

  describe "SMS -> 2h -> SMS -> 3h with dummy steps" do
    setup context do
      config =
        TestConfiguration.base_config()
        |> TestConfiguration.with_survey_retries_config(%{
          sms_retry_configuration: "2h",
          fallback_delay: "3h"
        })
        |> TestConfiguration.with_retries([2])
        |> TestConfiguration.with_fallback_delay(3)

      init_sms(config, context)
    end

    test "no user interaction", %{
      expected_histogram: expected_histogram,
      assert_histogram: assert_histogram,
      histogram_hour: histogram_hour
    } do
      set_current_time("2019-12-23T09:00:00Z")

      expected_histogram.([])
      |> assert_histogram.(
        "Histogram should be empty since respondent is still in state = pending"
      )

      # First poll, activate the respondent
      broker_poll()

      expected_histogram.([%{hour: histogram_hour.(%{attempt: 1}), respondents: 1}])
      |> assert_histogram.("The respondent should be in the first attempt active column")

      time_passes(hours: 1)

      expected_histogram.([
        %{hour: histogram_hour.(%{attempt: 1, hours_after: 1}), respondents: 1}
      ])
      |> assert_histogram.("the respondent should be in the first attempt - first hour column")

      time_passes(hours: 1)

      # Second poll, it should retry the first question
      broker_poll()

      expected_histogram.([%{hour: histogram_hour.(%{attempt: 2}), respondents: 1}])
      |> assert_histogram.("The respondent should be in the second attempt active column")

      time_passes(hours: 2)

      expected_histogram.([
        %{hour: histogram_hour.(%{attempt: 2, hours_after: 2}), respondents: 1}
      ])
      |> assert_histogram.("the respondent should be in the second attempt - second hour column")

      time_passes(hours: 1)

      # Third poll, it should fail the respondent
      broker_poll()

      # Respondent should have been removed from the Histogram
      expected_histogram.([])
      |> assert_histogram.("Respondent should have been removed from the Histogram")
    end

    test "user interactions and failed-respondent ending", %{
      expected_histogram: expected_histogram,
      assert_histogram: assert_histogram,
      histogram_hour: histogram_hour,
      respondent_reply: respondent_reply
    } do
      set_current_time("2019-12-23T09:00:00Z")

      expected_histogram.([])
      |> assert_histogram.(
        "Histogram should be empty since respondent is still in state = pending"
      )

      # First poll, activate the respondent
      broker_poll()

      expected_histogram.([%{hour: histogram_hour.(%{attempt: 1}), respondents: 1}])
      |> assert_histogram.("The respondent should be in the first attempt active column")

      time_passes(hours: 1)

      expected_histogram.([
        %{hour: histogram_hour.(%{attempt: 1, hours_after: 1}), respondents: 1}
      ])
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

      expected_histogram.([
        %{hour: histogram_hour.(%{attempt: 2, hours_after: 1}), respondents: 1}
      ])
      |> assert_histogram.(
        "the respondent should be in the the second attempt - first hour column"
      )

      # respondent responses the second question
      respondent_reply.("Yes")

      expected_histogram.([%{hour: histogram_hour.(%{attempt: 2}), respondents: 1}])
      |> assert_histogram.("the respondent should return to the second attempt active column")

      time_passes(hours: 2)

      expected_histogram.([
        %{hour: histogram_hour.(%{attempt: 2, hours_after: 2}), respondents: 1}
      ])
      |> assert_histogram.(
        "the respondent should be in the second attempt - first hour column again"
      )

      time_passes(hours: 1)

      # Third poll, it should fail the respondent
      broker_poll()

      # Respondent should have been removed from the Histogram
      expected_histogram.([])
      |> assert_histogram.("Respondent should have been removed from the Histogram")
    end
  end

  describe "SMS -> 2h -> SMS -> 3h with partial skip logic steps" do
    setup context do
      config =
        TestConfiguration.base_config()
        |> TestConfiguration.with_steps(@flag_steps_partial_skip_logic)
        |> TestConfiguration.with_survey_retries_config(%{
          sms_retry_configuration: "2h",
          fallback_delay: "3h"
        })
        |> TestConfiguration.with_retries([2])
        |> TestConfiguration.with_fallback_delay(3)

      init_sms(config, context)
    end

    test "respondent ends survey", %{
      expected_histogram: expected_histogram,
      assert_histogram: assert_histogram,
      histogram_hour: histogram_hour,
      respondent_reply: respondent_reply
    } do
      set_current_time("2019-12-23T09:00:00Z")

      # First poll, activate the respondent
      broker_poll()

      expected_histogram.([%{hour: histogram_hour.(%{attempt: 1}), respondents: 1}])
      |> assert_histogram.("The respondent should be in the first attempt active column")

      respondent_reply.("Yes")

      expected_histogram.([])
      |> assert_histogram.("The histogram should be empty since respondent completed the survey")
    end
  end

  describe "SMS -> 2h -> IVR with dummy steps" do
    setup do
      test_channel = TestChannel.new()
      channel = insert(:channel, settings: test_channel |> TestChannel.settings(), type: "sms")
      test_fallback_channel = TestChannel.new()

      fallback_channel =
        insert(:channel, settings: test_fallback_channel |> TestChannel.settings(), type: "ivr")

      quiz = insert(:questionnaire, steps: @dummy_steps)
      sequence_mode = ["sms", "ivr"]

      survey =
        insert(:survey, %{
          schedule: Schedule.always(),
          state: :running,
          questionnaires: [quiz],
          mode: [sequence_mode],
          fallback_delay: "3h"
        })

      group =
        insert(:respondent_group, survey: survey, respondents_count: 1)
        |> Repo.preload([:channels])

      RespondentGroupChannel.changeset(%RespondentGroupChannel{}, %{
        respondent_group_id: group.id,
        channel_id: channel.id,
        mode: channel.type
      })
      |> Repo.insert()

      RespondentGroupChannel.changeset(%RespondentGroupChannel{}, %{
        respondent_group_id: group.id,
        channel_id: fallback_channel.id,
        mode: fallback_channel.type
      })
      |> Repo.insert()

      respondent = insert(:respondent, survey: survey, respondent_group: group)
      #      phone_number = respondent.sanitized_phone_number

      survey =
        survey
        |> Survey.changeset(%{sms_retry_configuration: "2h", ivr_retry_configuration: "2h"})
        |> Repo.update!()

      histogram_flow = [
        %{delay: 0, type: "sms"},
        contacting_slot("sms", 2),
        contacting_slot("ivr", 3),
        contacting_slot("ivr", 2)
      ]

      expected_histogram = fn actives -> %{actives: actives, flow: histogram_flow} end

      histogram_hour = fn config -> histogram_hour(histogram_flow, config) end

      assert_histogram = fn histogram, message -> assert_histogram(survey, histogram, message) end

      {:ok,
       %{
         survey: survey,
         respondent: respondent,
         expected_histogram: expected_histogram,
         assert_histogram: assert_histogram,
         histogram_hour: histogram_hour
       }}
    end

    test "fallback test", %{
      expected_histogram: expected_histogram,
      assert_histogram: assert_histogram,
      histogram_hour: histogram_hour
    } do
      set_current_time("2019-12-23T09:00:00Z")

      # First poll, activate the respondent
      broker_poll()

      expected_histogram.([%{hour: histogram_hour.(%{attempt: 1}), respondents: 1}])
      |> assert_histogram.("the respondent should be in the first attempt active column")

      time_passes(hours: 2)
      # Second poll, retry the question
      broker_poll()

      expected_histogram.([%{hour: histogram_hour.(%{attempt: 2}), respondents: 1}])
      |> assert_histogram.("the respondent should be in the second attempt active column")

      time_passes(hours: 3)
      # Third poll, retry the question - fallback to ivr mode
      broker_poll()

      expected_histogram.([%{hour: histogram_hour.(%{attempt: 3}), respondents: 1}])
      |> assert_histogram.("the respondent should be in the third attempt active column")
    end
  end

  describe "Mobileweb -> 2h -> Mobileweb -> 3h with dummy steps" do
    setup context do
      config =
        TestConfiguration.base_config()
        |> TestConfiguration.with_survey_retries_config(%{
          mobileweb_retry_configuration: "2h",
          fallback_delay: "3h"
        })
        |> TestConfiguration.with_retries([2])
        |> TestConfiguration.with_fallback_delay(3)

      init_mobileweb(config, context)
    end

    test "no user interaction", %{
      expected_histogram: expected_histogram,
      assert_histogram: assert_histogram,
      histogram_hour: histogram_hour
    } do
      set_current_time("2019-12-23T09:00:00Z")

      expected_histogram.([])
      |> assert_histogram.("the histogram should be empty")

      # 1st poll, activate the respondent
      broker_poll()

      expected_histogram.([%{hour: 0, respondents: 1}])
      |> assert_histogram.("the respondent should be in the 1st column")

      time_passes(hours: 1)

      expected_histogram.([
        %{hour: histogram_hour.(%{attempt: 1, hours_after: 1}), respondents: 1}
      ])
      |> assert_histogram.("the respondent should be in the first attempt - first hour column")

      time_passes(hours: 1)

      # 2nd poll, retry the respondent
      broker_poll()

      expected_histogram.([%{hour: histogram_hour.(%{attempt: 2}), respondents: 1}])
      |> assert_histogram.("the respondent should be in the the second attempt active column")

      time_passes(hours: 2)

      expected_histogram.([
        %{hour: histogram_hour.(%{attempt: 2, hours_after: 2}), respondents: 1}
      ])
      |> assert_histogram.("the respondent should be in the second attempt - second hour column")

      time_passes(hours: 1)

      # 3rd and last poll
      broker_poll()

      # As the respondent had no more retries left, the histogram should be empty
      expected_histogram.([])
      |> assert_histogram.("the histogram should be empty")
    end
  end

  describe "RetriesHistogram.add_new_respondent" do
    setup context do
      config =
        TestConfiguration.base_config()
        |> TestConfiguration.with_survey_retries_config(%{
          sms_retry_configuration: "3h",
          fallback_delay: "3h"
        })
        |> TestConfiguration.with_retries([3])
        |> TestConfiguration.with_fallback_delay(3)

      init_sms(config, context)
    end

    test "should reallocate respondent if was already in histogram", %{
      respondent: respondent,
      expected_histogram: expected_histogram,
      assert_histogram: assert_histogram,
      histogram_hour: histogram_hour
    } do
      set_actual_time()

      add_respondent_to_histogram = fn r ->
        RetriesHistogram.add_new_respondent(r, %Session{respondent: r}, 180)
      end

      update_respondent_attempt = fn respondent, attempt ->
        Repo.get(Respondent, respondent.id)
        |> Respondent.changeset(%{stats: %Stats{attempts: %{"sms" => attempt}}, mode: ["sms"]})
        |> Repo.update!()
      end

      respondent
      |> update_respondent_attempt.(1)
      |> add_respondent_to_histogram.()

      expected_histogram.([%{hour: histogram_hour.(%{attempt: 1}), respondents: 1}])
      |> assert_histogram.("The respondent should be in the first attempt slot")

      respondent
      |> update_respondent_attempt.(2)
      |> add_respondent_to_histogram.()

      expected_histogram.([%{hour: histogram_hour.(%{attempt: 2}), respondents: 1}])
      |> assert_histogram.("The respondent should be in the second attempt slot")
    end
  end

  defp assert_histogram(survey, expected_histogram, message) do
    [actual_histogram] = Ask.RetriesHistogram.survey_histograms(survey)

    assert expected_histogram == actual_histogram,
           "#{message}: \n\texpected histogram: #{inspect(expected_histogram)} \n\tactual histogram: #{
             inspect(actual_histogram)
           }"
  end

  defp initialize_survey(mode, survey_configuration, steps) do
    [survey, _group, _test_channel, respondent, _phone_number] =
      create_running_survey_with_channel_and_respondent(steps, mode)

    survey = survey |> Survey.changeset(survey_configuration) |> Repo.update!()
    %{survey: survey, respondent: respondent}
  end

  defp init_mode(mode, config) do
    %{survey: survey, respondent: respondent} =
      initialize_survey(mode, config.survey_retry_config, config.questionnaire_steps)

    %{histogram_flow: expected_histogram_flow, histogram_hour: histogram_hour} =
      configure_retries_and_fallback(mode, config.retries, config.fallback_delay)

    expected_histogram = fn actives -> %{actives: actives, flow: expected_histogram_flow} end
    assert_histogram = fn histogram, message -> assert_histogram(survey, histogram, message) end

    %{
      survey: survey,
      respondent: respondent,
      expected_histogram: expected_histogram,
      assert_histogram: assert_histogram,
      histogram_hour: histogram_hour
    }
  end

  defp init_ivr(config, _context) do
    %{respondent: respondent} = context = init_mode("ivr", config)
    call_failed = fn -> call_failed(build_conn(), respondent.id) end

    #    respondent_reply = fn response -> VerboiceChannel.callback(build_conn(), %{"respondent" => respondent.id, "Digits" => response}) end

    {:ok,
     Map.merge(context, %{
       call_failed: call_failed,
       respondent_reply: fn reply -> respondent_reply(respondent.id, reply, "ivr") end
     })}
  end

  defp init_sms(config, _context) do
    %{respondent: respondent} = context = init_mode("sms", config)
    respondent_reply = fn reply -> respondent_reply(respondent.id, reply, "sms") end
    {:ok, Map.put(context, :respondent_reply, respondent_reply)}
  end

  defp init_mobileweb(config, _context) do
    context = init_mode("mobileweb", config)
    {:ok, context}
  end

  defp call_failed(conn, respondent_id),
    do:
      VerboiceChannel.callback(conn, %{
        "path" => ["status", respondent_id, "token"],
        "CallStatus" => "failed",
        "CallDuration" => "10",
        "CallStatusReason" => "some random reason",
        "CallStatusCode" => "42",
        "CallSid" => "call-sid"
      })

  defp configure_retries_and_fallback(type, retries_hours, fallback_delay_hours)
       when type in ["sms", "mobileweb"] do
    flow =
      base_flow(type, retries_hours)
      |> append_last_contacting_slot("end", fallback_delay_hours)

    %{histogram_flow: flow, histogram_hour: fn config -> histogram_hour(flow, config) end}
  end

  defp configure_retries_and_fallback("ivr" = type, retries_hours, _fallback_delay_hours) do
    flow = base_flow(type, retries_hours)
    %{histogram_flow: flow, histogram_hour: fn config -> histogram_hour(flow, config) end}
  end

  defp base_flow(type, retries_hours),
    do:
      retries_hours
      |> Enum.reduce([%{delay: 0, type: type}], fn x, accum ->
        append_last_contacting_slot(accum, type, x)
      end)

  defp append_last_contacting_slot(list, type, delay), do: list ++ [contacting_slot(type, delay)]

  # Calculates the hour in the histogram that represents the given attempt and the hours that passed from this one
  # If no :hours_after, 0 is considered
  defp histogram_hour(flow, %{attempt: attempt, hours_after: hours_after_attempt}) do
    base_hours =
      flow
      |> Enum.slice(0, attempt)
      |> Enum.map(fn %{delay: delay} -> delay end)
      |> Enum.sum()

    base_hours + hours_after_attempt
  end

  defp histogram_hour(flow, %{attempt: _attempt} = map),
    do: histogram_hour(flow, Map.put(map, :hours_after, 0))

  defp contacting_slot(type, delay), do: %{delay: delay, label: "#{delay}h", type: type}
end

defmodule TestConfiguration do
  use Ask.DummySteps

  def base_config,
    do: %{
      survey_retry_config: %{},
      retries: [],
      fallback_delay: 0,
      questionnaire_steps: @dummy_steps
    }

  def with_steps(conf, steps), do: Map.put(conf, :questionnaire_steps, steps)

  def with_survey_retries_config(conf, retries_config),
    do: Map.put(conf, :survey_retry_config, retries_config)

  def with_retries(conf, retries), do: Map.put(conf, :retries, retries)

  def with_fallback_delay(conf, fallback_delay),
    do: Map.put(conf, :fallback_delay, fallback_delay)
end
