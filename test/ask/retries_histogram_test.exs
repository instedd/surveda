defmodule Ask.RetriesHistogramTest do
  use ExUnit.Case
  use Ask.DataCase
  use Ask.MockTime
  alias Ask.{RetriesHistogram, Survey, RetryStat}

  test "flow with no retries" do
    mode = "sms"
    survey = insert(:survey, %{fallback_delay: "10h", mode: [[mode]]})
    [%{flow: flow}] = survey |> RetriesHistogram.survey_histograms()
    assert flow == [%{type: mode, delay: 0}, %{type: "end", delay: 10, label: "10h"}]
  end

  defp flow_with_retries("ivr" = mode) do
    survey =
      insert(
        :survey,
        Map.merge(retry_configuration(mode, "1h 2h 3h"), %{fallback_delay: "5h", mode: [[mode]]})
      )

    [%{flow: flow}] = survey |> RetriesHistogram.survey_histograms()

    assert flow == [
             %{type: mode, delay: 0},
             %{type: mode, delay: 1, label: "1h"},
             %{type: mode, delay: 2, label: "2h"},
             %{type: mode, delay: 3, label: "3h"}
           ]
  end

  defp flow_with_retries(mode) do
    survey =
      insert(
        :survey,
        Map.merge(retry_configuration(mode, "1h 2h 3h"), %{fallback_delay: "5h", mode: [[mode]]})
      )

    [%{flow: flow}] = survey |> RetriesHistogram.survey_histograms()

    assert flow == [
             %{type: mode, delay: 0},
             %{type: mode, delay: 1, label: "1h"},
             %{type: mode, delay: 2, label: "2h"},
             %{type: mode, delay: 3, label: "3h"},
             %{type: "end", delay: 5, label: "5h"}
           ]
  end

  test "flow with retries" do
    flow_with_retries("ivr")
    flow_with_retries("sms")
    flow_with_retries("mobileweb")
  end

  test "flow sms -> ivr" do
    mode = ["sms", "ivr"]

    survey =
      insert(:survey, %{
        sms_retry_configuration: "1h 2h 3h",
        ivr_retry_configuration: "5h 6h 7h",
        fallback_delay: "4h",
        mode: [mode]
      })

    [%{flow: flow}] = survey |> RetriesHistogram.survey_histograms()

    assert flow == [
             %{type: "sms", delay: 0},
             %{type: "sms", delay: 1, label: "1h"},
             %{type: "sms", delay: 2, label: "2h"},
             %{type: "sms", delay: 3, label: "3h"},
             %{type: "ivr", delay: 4, label: "4h"},
             %{type: "ivr", delay: 5, label: "5h"},
             %{type: "ivr", delay: 6, label: "6h"},
             %{type: "ivr", delay: 7, label: "7h"}
           ]
  end

  test "flow ivr -> sms" do
    mode = ["ivr", "sms"]

    survey =
      insert(:survey, %{
        ivr_retry_configuration: "1h 2h 3h",
        sms_retry_configuration: "5h 6h 7h",
        fallback_delay: "4h",
        mode: [mode]
      })

    [%{flow: flow}] = survey |> RetriesHistogram.survey_histograms()

    assert flow == [
             %{type: "ivr", delay: 0},
             %{type: "ivr", delay: 1, label: "1h"},
             %{type: "ivr", delay: 2, label: "2h"},
             %{type: "ivr", delay: 3, label: "3h"},
             %{type: "sms", delay: 4, label: "4h"},
             %{type: "sms", delay: 5, label: "5h"},
             %{type: "sms", delay: 6, label: "6h"},
             %{type: "sms", delay: 7, label: "7h"},
             %{type: "end", delay: 4, label: "4h"}
           ]
  end

  test "flow mobileweb -> ivr -> sms" do
    mode = ["mobileweb", "ivr", "sms"]

    survey =
      insert(:survey, %{
        sms_retry_configuration: "1h 2h 3h",
        ivr_retry_configuration: "5h 6h 7h",
        mobileweb_retry_configuration: "2h 5h 8h",
        fallback_delay: "4h",
        mode: [mode]
      })

    [%{flow: flow}] = survey |> RetriesHistogram.survey_histograms()

    assert flow == [
             %{type: "mobileweb", delay: 0},
             %{type: "mobileweb", delay: 2, label: "2h"},
             %{type: "mobileweb", delay: 5, label: "5h"},
             %{type: "mobileweb", delay: 8, label: "8h"},
             %{type: "ivr", delay: 4, label: "4h"},
             %{type: "ivr", delay: 5, label: "5h"},
             %{type: "ivr", delay: 6, label: "6h"},
             %{type: "ivr", delay: 7, label: "7h"},
             %{type: "sms", delay: 4, label: "4h"},
             %{type: "sms", delay: 1, label: "1h"},
             %{type: "sms", delay: 2, label: "2h"},
             %{type: "sms", delay: 3, label: "3h"},
             %{type: "end", delay: 4, label: "4h"}
           ]
  end

  defp test_actives_no_retries("ivr" = mode) do
    survey = insert(:survey, mode: [[mode]])
    set_actual_time()

    assert histogram_actives(survey) == []

    {:ok, %{id: stat_id}} =
      RetryStat.add(%{
        attempt: 1,
        mode: [mode],
        retry_time: retry_time(SystemTime.time().now(), 0),
        ivr_active: true,
        survey_id: survey.id
      })

    {:ok, %{id: stat_id_2}} =
      RetryStat.add(%{
        attempt: 1,
        mode: [mode],
        retry_time: retry_time(SystemTime.time().now(), 1),
        ivr_active: true,
        survey_id: survey.id
      })

    assert histogram_actives(survey) == [%{hour: 0, respondents: 2}],
           "Histogram must take into account all the respondents that are ivr_active without taking into account the retry_time"

    time_passes(hours: 1)
    assert histogram_actives(survey) == [%{hour: 0, respondents: 2}]

    {:ok} = RetryStat.subtract(stat_id)

    assert histogram_actives(survey) == [%{hour: 0, respondents: 1}]

    {:ok} = RetryStat.subtract(stat_id_2)

    assert histogram_actives(survey) == []
  end

  defp test_actives_no_retries(mode) do
    survey = insert(:survey, %{fallback_delay: "2h", mode: [[mode]]})
    set_actual_time()

    assert histogram_actives(survey) == []

    {:ok, %{id: stat_id}} =
      RetryStat.add(%{
        attempt: 1,
        mode: [mode],
        retry_time: retry_time(SystemTime.time().now, 2),
        ivr_active: false,
        survey_id: survey.id
      })

    assert histogram_actives(survey) == [%{hour: 0, respondents: 1}]

    time_passes(hours: 1)
    assert histogram_actives(survey) == [%{hour: 1, respondents: 1}]

    time_passes(hours: 1)
    assert histogram_actives(survey) == [%{hour: 2, respondents: 1}]

    time_passes(hours: 1)
    assert histogram_actives(survey) == [%{hour: 2, respondents: 1}]

    {:ok} = RetryStat.subtract(stat_id)

    assert histogram_actives(survey) == []
  end

  @tag :time_mock
  test "actives 1 mode no retries" do
    test_actives_no_retries("sms")
    test_actives_no_retries("ivr")
    test_actives_no_retries("mobileweb")
  end

  @tag :time_mock
  test "actives 1 mode 1 retry" do
    test_actives_1_retry("sms")
    test_actives_1_retry("ivr")
    test_actives_1_retry("mobileweb")
  end

  defp test_actives_1_retry("ivr" = mode) do
    set_actual_time()
    survey = insert(:survey, Map.put(retry_configuration(mode, "2h"), :mode, [[mode]]))

    assert histogram_actives(survey) == []

    {:ok, %{id: active_stat_id}} =
      RetryStat.add(%{
        attempt: 1,
        mode: [mode],
        retry_time: retry_time(SystemTime.time().now, 2),
        ivr_active: true,
        survey_id: survey.id
      })

    assert histogram_actives(survey) == [%{hour: 0, respondents: 1}]

    time_passes(hours: 1)
    assert histogram_actives(survey) == [%{hour: 0, respondents: 1}]

    time_passes(hours: 1)
    assert histogram_actives(survey) == [%{hour: 0, respondents: 1}]

    {:ok} = RetryStat.subtract(active_stat_id)

    {:ok, %{id: waiting_stat_id}} =
      RetryStat.add(%{
        attempt: 1,
        mode: [mode],
        retry_time: retry_time(SystemTime.time().now, 2),
        ivr_active: false,
        survey_id: survey.id
      })

    assert histogram_actives(survey) == [%{hour: 0, respondents: 1}]

    time_passes(hours: 1)
    assert histogram_actives(survey) == [%{hour: 1, respondents: 1}]

    time_passes(hours: 1)
    assert histogram_actives(survey) == [%{hour: 1, respondents: 1}]

    {:ok} = RetryStat.subtract(waiting_stat_id)

    {:ok, %{id: active_stat_id}} =
      RetryStat.add(%{
        attempt: 2,
        mode: [mode],
        retry_time: retry_time(SystemTime.time().now, 0),
        ivr_active: true,
        survey_id: survey.id
      })

    assert histogram_actives(survey) == [%{hour: 2, respondents: 1}]

    time_passes(hours: 1)
    assert histogram_actives(survey) == [%{hour: 2, respondents: 1}]

    {:ok} = RetryStat.subtract(active_stat_id)

    assert histogram_actives(survey) == []

    time_passes(hours: 1)
    assert histogram_actives(survey) == []
  end

  defp test_actives_1_retry(mode) do
    set_actual_time()

    survey =
      insert(
        :survey,
        Map.merge(retry_configuration(mode, "2h"), %{fallback_delay: "3h", mode: [[mode]]})
      )

    assert histogram_actives(survey) == []

    {:ok, %{id: initial_stat_id}} =
      RetryStat.add(%{
        attempt: 1,
        mode: [mode],
        retry_time: retry_time(SystemTime.time().now, 2),
        ivr_active: false,
        survey_id: survey.id
      })

    assert histogram_actives(survey) == [%{hour: 0, respondents: 1}]
    time_passes(hours: 1)
    assert histogram_actives(survey) == [%{hour: 1, respondents: 1}]

    {:ok} = RetryStat.subtract(initial_stat_id)

    {:ok, %{id: last_stat_id}} =
      RetryStat.add(%{
        attempt: 2,
        mode: [mode],
        retry_time: retry_time(SystemTime.time().now, 3),
        ivr_active: false,
        survey_id: survey.id
      })

    assert histogram_actives(survey) == [%{hour: 2, respondents: 1}]

    time_passes(hours: 1)
    assert histogram_actives(survey) == [%{hour: 3, respondents: 1}]

    time_passes(hours: 1)
    assert histogram_actives(survey) == [%{hour: 4, respondents: 1}]

    time_passes(hours: 1)
    assert histogram_actives(survey) == [%{hour: 5, respondents: 1}]

    time_passes(hours: 1)
    assert histogram_actives(survey) == [%{hour: 5, respondents: 1}]

    {:ok} = RetryStat.subtract(last_stat_id)

    assert histogram_actives(survey) == []
  end

  @tag :time_mock
  test "actives sms -> ivr" do
    mode = ["ivr", "sms"]
    survey = insert(:survey, %{fallback_delay: "2h", mode: [mode]})
    set_actual_time()

    assert histogram_actives(survey) == []

    {:ok, %{id: ivr_active_stat_id}} =
      RetryStat.add(%{
        attempt: 1,
        mode: mode,
        retry_time: retry_time(SystemTime.time().now, 2),
        ivr_active: true,
        survey_id: survey.id
      })

    assert histogram_actives(survey) == [%{hour: 0, respondents: 1}]

    time_passes(hours: 1)
    assert histogram_actives(survey) == [%{hour: 0, respondents: 1}]

    {:ok} = RetryStat.subtract(ivr_active_stat_id)

    {:ok, %{id: sms_stat_id}} =
      RetryStat.add(%{
        attempt: 2,
        mode: mode,
        retry_time: retry_time(SystemTime.time().now, 2),
        ivr_active: false,
        survey_id: survey.id
      })

    assert histogram_actives(survey) == [%{hour: 2, respondents: 1}]

    time_passes(hours: 1)
    assert histogram_actives(survey) == [%{hour: 3, respondents: 1}]

    time_passes(hours: 1)
    assert histogram_actives(survey) == [%{hour: 4, respondents: 1}]

    time_passes(hours: 1)
    assert histogram_actives(survey) == [%{hour: 4, respondents: 1}]

    {:ok} = RetryStat.subtract(sms_stat_id)

    assert histogram_actives(survey) == []
  end

  @tag :time_mock
  test "actives ivr -> sms" do
    mode = ["sms", "ivr"]
    survey = insert(:survey, %{fallback_delay: "2h", mode: [mode]})
    set_actual_time()

    assert histogram_actives(survey) == []

    {:ok, %{id: sms_stat_id}} =
      RetryStat.add(%{
        attempt: 1,
        mode: mode,
        retry_time: retry_time(SystemTime.time().now, 2),
        ivr_active: false,
        survey_id: survey.id
      })

    assert histogram_actives(survey) == [%{hour: 0, respondents: 1}]

    time_passes(hours: 1)
    assert histogram_actives(survey) == [%{hour: 1, respondents: 1}]

    time_passes(hours: 1)
    assert histogram_actives(survey) == [%{hour: 1, respondents: 1}]

    {:ok} = RetryStat.subtract(sms_stat_id)

    {:ok, %{id: ivr_active_stat_id}} =
      RetryStat.add(%{
        attempt: 2,
        mode: mode,
        retry_time: retry_time(SystemTime.time().now, 2),
        ivr_active: true,
        survey_id: survey.id
      })

    assert histogram_actives(survey) == [%{hour: 2, respondents: 1}]

    time_passes(hours: 1)
    assert histogram_actives(survey) == [%{hour: 2, respondents: 1}]

    {:ok} = RetryStat.subtract(ivr_active_stat_id)

    assert histogram_actives(survey) == []
  end

  defp histogram_actives(%Survey{} = survey) do
    [%{actives: actives}] = survey |> RetriesHistogram.survey_histograms()
    actives
  end

  defp retry_configuration("sms", retry_configuration),
    do: %{sms_retry_configuration: retry_configuration}

  defp retry_configuration("ivr", retry_configuration),
    do: %{ivr_retry_configuration: retry_configuration}

  defp retry_configuration("mobileweb", retry_configuration),
    do: %{mobileweb_retry_configuration: retry_configuration}

  defp retry_time(now, delay), do: now |> Timex.shift(hours: delay) |> RetryStat.retry_time()
end
