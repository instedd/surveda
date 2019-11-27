defmodule Ask.RetriesHistogramTest do
  use ExUnit.Case
  use Ask.ModelCase
  alias Ask.{RetriesHistogram, Survey, RetryStat}

  test "flow with no retries" do
    mode = ["sms"]
    survey = insert(:survey, %{fallback_delay: "10h"})
    stats = %{survey_id: survey.id} |> RetryStat.stats()
    %{flow: flow} = survey |> RetriesHistogram.mode_sequence_histogram(stats, [mode], Timex.now())

    assert flow == [%{type: mode, delay: 0}, %{type: "end", delay: 10, label: "10h"}]
  end

  defp flow_with_retries("ivr" = mode) do
    survey =
      insert(:survey, Map.put(retry_configuration(mode, "1h 2h 3h"), :fallback_delay, "5h"))

    stats = %{survey_id: survey.id} |> RetryStat.stats()
    %{flow: flow} = survey |> RetriesHistogram.mode_sequence_histogram(stats, [mode], Timex.now())

    assert flow == [
             %{type: mode, delay: 0},
             %{type: mode, delay: 1, label: "1h"},
             %{type: mode, delay: 2, label: "2h"},
             %{type: mode, delay: 3, label: "3h"}
           ]
  end

  defp flow_with_retries(mode) do
    survey =
      insert(:survey, Map.put(retry_configuration(mode, "1h 2h 3h"), :fallback_delay, "5h"))

    stats = %{survey_id: survey.id} |> RetryStat.stats()
    %{flow: flow} = survey |> RetriesHistogram.mode_sequence_histogram(stats, mode, Timex.now())

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
  end

  test "flow sms -> ivr" do
    mode = ["sms", "ivr"]

    survey =
      insert(:survey, %{
        sms_retry_configuration: "1h 2h 3h",
        ivr_retry_configuration: "5h 6h 7h",
        fallback_delay: "4h"
      })

    stats = %{survey_id: survey.id} |> RetryStat.stats()
    %{flow: flow} = survey |> RetriesHistogram.mode_sequence_histogram(stats, mode, Timex.now())

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
        fallback_delay: "4h"
      })

    stats = %{survey_id: survey.id} |> RetryStat.stats()
    %{flow: flow} = survey |> RetriesHistogram.mode_sequence_histogram(stats, mode, Timex.now())

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
        fallback_delay: "4h"
      })

    stats = %{survey_id: survey.id} |> RetryStat.stats()
    %{flow: flow} = survey |> RetriesHistogram.mode_sequence_histogram(stats, mode, Timex.now())

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
    survey = insert(:survey)
    now = Timex.now()

    assert histogram_actives(survey, [mode], now) == []

    filter = %{attempt: 1, mode: [mode], retry_time: "", survey_id: survey.id}

    filter
    |> increase_stat(1)

    assert histogram_actives(survey, [mode], now) == [%{hour: 0, respondents: 1}]

    now = now |> Timex.shift(hours: 1)
    assert histogram_actives(survey, [mode], now) == [%{hour: 0, respondents: 1}]

    filter
    |> decrease_stat(1)

    assert histogram_actives(survey, [mode], now) == []
  end

  defp test_actives_no_retries(mode) do
    survey = insert(:survey, %{fallback_delay: "2h"})
    now = Timex.now()

    assert histogram_actives(survey, [mode], now) == []

    filter = %{attempt: 1, mode: [mode], retry_time: retry_time(now, 2), survey_id: survey.id}

    filter
    |> increase_stat(1)

    assert histogram_actives(survey, [mode], now) == [%{hour: 0, respondents: 1}]

    now = now |> Timex.shift(hours: 1)
    assert histogram_actives(survey, [mode], now) == [%{hour: 1, respondents: 1}]

    now = now |> Timex.shift(hours: 1)
    assert histogram_actives(survey, [mode], now) == [%{hour: 2, respondents: 1}]

    now = now |> Timex.shift(hours: 1)
    assert histogram_actives(survey, [mode], now) == [%{hour: 2, respondents: 1}]

    filter
    |> decrease_stat(1)

    assert histogram_actives(survey, [mode], now) == []
  end

  test "actives 1 mode no retries" do
    test_actives_no_retries("sms")
    test_actives_no_retries("ivr")
    test_actives_no_retries("mobileweb")
  end

  test "actives 1 mode 1 retry" do
    test_actives_1_retry("sms")
    test_actives_1_retry("ivr")
    test_actives_1_retry("mobileweb")
  end

  defp test_actives_1_retry("ivr" = mode) do
    now = Timex.now()
    survey = insert(:survey, mode |> retry_configuration("2h"))

    assert histogram_actives(survey, [mode], now) == []

    active_filter = %{attempt: 1, mode: [mode], retry_time: "", survey_id: survey.id}

    active_filter
    |> increase_stat(1)

    assert histogram_actives(survey, [mode], now) == [%{hour: 0, respondents: 1}]

    now = now |> Timex.shift(hours: 1)
    assert histogram_actives(survey, [mode], now) == [%{hour: 0, respondents: 1}]

    now = now |> Timex.shift(hours: 1)
    assert histogram_actives(survey, [mode], now) == [%{hour: 0, respondents: 1}]

    active_filter
    |> decrease_stat(1)

    waiting_filter = %{
      attempt: 1,
      mode: [mode],
      retry_time: retry_time(now, 2),
      survey_id: survey.id
    }

    waiting_filter
    |> increase_stat(1)

    assert histogram_actives(survey, [mode], now) == []

    now = now |> Timex.shift(hours: 1)
    assert histogram_actives(survey, [mode], now) == [%{hour: 1, respondents: 1}]

    now = now |> Timex.shift(hours: 1)
    assert histogram_actives(survey, [mode], now) == [%{hour: 1, respondents: 1}]

    waiting_filter
    |> decrease_stat(1)

    active_filter = %{attempt: 2, mode: [mode], retry_time: "", survey_id: survey.id}

    active_filter
    |> increase_stat(1)

    assert histogram_actives(survey, [mode], now) == [%{hour: 2, respondents: 1}]

    now = now |> Timex.shift(hours: 1)
    assert histogram_actives(survey, [mode], now) == [%{hour: 2, respondents: 1}]

    active_filter
    |> decrease_stat(1)

    assert histogram_actives(survey, [mode], now) == []

    now = now |> Timex.shift(hours: 1)
    assert histogram_actives(survey, [mode], now) == []
  end

  defp test_actives_1_retry(mode) do
    now = Timex.now()
    survey = insert(:survey, Map.put(retry_configuration(mode, "2h"), :fallback_delay, "3h"))

    assert histogram_actives(survey, [mode], now) == []

    initial_filter = %{
      attempt: 1,
      mode: [mode],
      retry_time: retry_time(now, 2),
      survey_id: survey.id
    }

    initial_filter
    |> increase_stat(1)

    assert histogram_actives(survey, [mode], now) == [%{hour: 0, respondents: 1}]

    now = now |> Timex.shift(hours: 1)
    assert histogram_actives(survey, [mode], now) == [%{hour: 1, respondents: 1}]

    initial_filter
    |> decrease_stat(1)

    last_filter = %{
      attempt: 2,
      mode: [mode],
      retry_time: retry_time(now, 3),
      survey_id: survey.id
    }

    last_filter
    |> increase_stat(1)

    assert histogram_actives(survey, [mode], now) == [%{hour: 2, respondents: 1}]

    now = now |> Timex.shift(hours: 1)
    assert histogram_actives(survey, [mode], now) == [%{hour: 3, respondents: 1}]

    now = now |> Timex.shift(hours: 1)
    assert histogram_actives(survey, [mode], now) == [%{hour: 4, respondents: 1}]

    now = now |> Timex.shift(hours: 1)
    assert histogram_actives(survey, [mode], now) == [%{hour: 5, respondents: 1}]

    now = now |> Timex.shift(hours: 1)
    assert histogram_actives(survey, [mode], now) == [%{hour: 5, respondents: 1}]

    last_filter
    |> decrease_stat(1)

    assert histogram_actives(survey, [mode], now) == []
  end

  test "actives sms -> ivr" do
    mode = ["ivr", "sms"]
    survey = insert(:survey, %{fallback_delay: "2h"})
    now = Timex.now()

    assert histogram_actives(survey, mode, now) == []

    ivr_active_filter = %{attempt: 1, mode: mode, retry_time: "", survey_id: survey.id}

    ivr_active_filter
    |> increase_stat(1)

    assert histogram_actives(survey, mode, now) == [%{hour: 0, respondents: 1}]

    now = now |> Timex.shift(hours: 1)
    assert histogram_actives(survey, mode, now) == [%{hour: 0, respondents: 1}]

    ivr_active_filter
    |> decrease_stat(1)

    sms_1_filter = %{attempt: 1, mode: mode, retry_time: retry_time(now, 2), survey_id: survey.id}

    sms_1_filter
    |> increase_stat(1)

    assert histogram_actives(survey, mode, now) == []

    now = now |> Timex.shift(hours: 1)
    assert histogram_actives(survey, mode, now) == [%{hour: 1, respondents: 1}]

    now = now |> Timex.shift(hours: 1)
    assert histogram_actives(survey, mode, now) == [%{hour: 1, respondents: 1}]

    sms_1_filter
    |> decrease_stat(1)

    sms_2_filter = %{attempt: 2, mode: mode, retry_time: retry_time(now, 2), survey_id: survey.id}

    sms_2_filter
    |> increase_stat(1)

    assert histogram_actives(survey, mode, now) == [%{hour: 2, respondents: 1}]

    now = now |> Timex.shift(hours: 1)
    assert histogram_actives(survey, mode, now) == [%{hour: 3, respondents: 1}]

    now = now |> Timex.shift(hours: 1)
    assert histogram_actives(survey, mode, now) == [%{hour: 4, respondents: 1}]

    now = now |> Timex.shift(hours: 1)
    assert histogram_actives(survey, mode, now) == [%{hour: 4, respondents: 1}]

    sms_2_filter
    |> decrease_stat(1)

    assert histogram_actives(survey, mode, now) == []
  end

  test "actives ivr -> sms" do
    mode = ["sms", "ivr"]
    survey = insert(:survey, %{fallback_delay: "2h"})
    now = Timex.now()

    assert histogram_actives(survey, mode, now) == []

    sms_filter = %{attempt: 1, mode: mode, retry_time: retry_time(now, 2), survey_id: survey.id}

    sms_filter
    |> increase_stat(1)

    assert histogram_actives(survey, mode, now) == [%{hour: 0, respondents: 1}]

    now = now |> Timex.shift(hours: 1)
    assert histogram_actives(survey, mode, now) == [%{hour: 1, respondents: 1}]

    now = now |> Timex.shift(hours: 1)
    assert histogram_actives(survey, mode, now) == [%{hour: 1, respondents: 1}]

    sms_filter
    |> decrease_stat(1)

    ivr_active_filter = %{attempt: 2, mode: mode, retry_time: "", survey_id: survey.id}

    ivr_active_filter
    |> increase_stat(1)

    assert histogram_actives(survey, mode, now) == [%{hour: 2, respondents: 1}]

    now = now |> Timex.shift(hours: 1)
    assert histogram_actives(survey, mode, now) == [%{hour: 2, respondents: 1}]

    ivr_active_filter
    |> decrease_stat(1)

    assert histogram_actives(survey, mode, now) == []
  end

  defp histogram_actives(%Survey{id: survey_id} = survey, mode, now) do
    stats = %{survey_id: survey_id} |> RetryStat.stats()
    %{actives: actives} = survey |> RetriesHistogram.mode_sequence_histogram(stats, mode, now)
    actives
  end

  defp retry_configuration("sms", retry_configuration),
    do: %{sms_retry_configuration: retry_configuration}

  defp retry_configuration("ivr", retry_configuration),
    do: %{ivr_retry_configuration: retry_configuration}

  defp retry_configuration("mobileweb", retry_configuration),
    do: %{mobileweb_retry_configuration: retry_configuration}

  defp retry_time(now, delay), do: now |> Timex.shift(hours: delay) |> RetryStat.retry_time()

  defp increase_stat(filter, n) when n <= 1 do
    {:ok} = RetryStat.add!(filter)
  end

  defp increase_stat(filter, n) do
    {:ok} = RetryStat.add!(filter)
    increase_stat(filter, n - 1)
  end

  defp decrease_stat(filter, n) when n <= 1 do
    {:ok} = RetryStat.subtract!(filter)
  end

  defp decrease_stat(filter, n) do
    {:ok} = RetryStat.subtract!(filter)
    decrease_stat(filter, n - 1)
  end
end
