defmodule Ask.RetriesHistogram do
  alias Ask.{Survey, RetryStat}

  def survey_histograms(%Survey{mode: mode} = survey) do
    stats = %{survey_id: survey.id} |> RetryStat.stats()
    mode |> Enum.map(fn mode -> survey |> mode_sequence_histogram(stats, mode, Timex.now()) end)
  end

  def mode_sequence_histogram(%Survey{} = survey, stats, mode, now),
    do: %{
      flow: survey |> retries_histogram_flow(mode),
      actives: survey |> retries_histogram_actives(stats, mode, now) |> clean_empty_slots()
    }

  defp retries_histogram_actives(%Survey{} = survey, stats, mode, now) do
    flow =
      survey
      |> retries_histogram_flow(mode)

    flow
    |> absolute_delay_flow()
    |> Stream.with_index()
    |> Enum.reduce([], fn {%{absolute_delay: absolute_delay, delay: delay, type: type}, idx},
                          acc ->
      acc ++
        attempt_respondents(%{
          stats: stats,
          mode: mode,
          attempt: %{
            idx: idx + 1,
            absolute_delay: absolute_delay,
            current_mode: type,
            delay: delay
          },
          now: now,
          attempts: Enum.count(flow),
          flow: flow
        })
    end)
  end

  defp attempt_respondents(%{
         stats: stats,
         mode: mode,
         attempt: %{
           idx: idx,
           absolute_delay: absolute_delay,
           delay: delay,
           current_mode: current_mode
         },
         now: now,
         attempts: attempts,
         flow: flow
       }) do
    count_current =
      count_actives(%{stats: stats, attempt: idx, mode: mode, current_mode: current_mode})

    %{type: previous_mode} = flow |> Enum.at(idx - 2)

    count_previous =
      count_previous_actives(%{
        stats: stats,
        now: now,
        attempt: idx - 1,
        mode: mode,
        delay: delay,
        current_mode: current_mode,
        previous_mode: previous_mode
      })

    [%{hour: absolute_delay, respondents: count_current}] ++
      [%{hour: absolute_delay - delay, respondents: count_previous}] ++
      waiting_respondents(%{
        stats: stats,
        mode: mode,
        attempt: %{
          idx: idx,
          absolute_delay: absolute_delay,
          delay: delay - 1,
          current_mode: current_mode
        },
        now: now,
        attempts: attempts
      })
  end

  defp attempt_respondents(%{attempt: %{idx: 1}}), do: []

  defp count_previous_actives(%{previous_mode: "ivr"}), do: 0

  defp count_previous_actives(%{
         stats: stats,
         now: now,
         attempt: attempt,
         mode: mode,
         delay: delay
       }),
       do: count_respondents(stats, now, attempt, mode, delay)

  defp count_previous_actives(_), do: 0

  defp count_actives(%{stats: stats, attempt: attempt, mode: mode, current_mode: "ivr"}),
    do:
      stats
      |> RetryStat.count(%{attempt: attempt, mode: mode, retry_time: "ivr_active"})

  defp count_actives(%{stats: stats, now: now, attempt: attempt, mode: mode, delay: delay}) do
    count_respondents(stats, now, attempt, mode, delay)
  end

  defp count_actives(_), do: 0

  defp waiting_respondents(%{
         stats: stats,
         mode: mode,
         attempt: %{
           idx: idx,
           absolute_delay: absolute_delay,
           delay: delay,
           current_mode: current_mode
         },
         now: now,
         attempts: attempts
       })
       when delay > 1 or (delay == 1 and attempts == idx and current_mode == "end") do
    count = count_respondents(stats, now, idx - 1, mode, delay)

    [%{hour: absolute_delay - delay, respondents: count}] ++
      waiting_respondents(%{
        stats: stats,
        mode: mode,
        attempt: %{
          idx: idx,
          absolute_delay: absolute_delay,
          delay: delay - 1,
          current_mode: current_mode
        },
        now: now,
        attempts: attempts
      })
  end

  defp waiting_respondents(%{
         stats: stats,
         mode: mode,
         attempt: %{idx: idx, absolute_delay: absolute_delay, delay: delay},
         now: now
       }) do
    count = count_respondents(stats, now, idx - 1, mode, delay, true)

    [%{hour: absolute_delay - delay, respondents: count}]
  end

  defp count_respondents(stats, now, attempt, mode, delay, overdue \\ nil) do
    retry_time =
      now
      |> Timex.shift(hours: delay)
      |> retry_time()

    stats
    |> RetryStat.count(%{attempt: attempt, mode: mode, retry_time: retry_time, overdue: overdue})
  end

  defp absolute_delay_flow(flow) do
    {flow, _} =
      flow
      |> Enum.map_reduce(0, fn %{type: type, delay: delay}, acc_delay ->
        {%{type: type, delay: delay, absolute_delay: delay + acc_delay}, delay + acc_delay}
      end)

    flow
  end

  defp clean_empty_slots(slots),
    do: slots |> Enum.filter(fn %{respondents: count} -> count > 0 end)

  defp retry_time(time), do: Timex.format!(time, "%Y%0m%0d%H", :strftime)

  defp retries_histogram_flow(%Survey{} = survey, mode_sequence) do
    flow =
      mode_sequence
      |> Stream.with_index()
      |> Enum.reduce([], fn {mode, idx}, acc -> acc ++ flow_retries(survey, mode, idx) end)

    flow ++ end_flow(survey, flow)
  end

  defp end_flow(survey, flow) do
    fallback_delay = survey |> Survey.fallback_delay() |> minutes_to_hours()
    [%{type: type}] = Enum.take(flow, -1)

    end_flow_delay(type, fallback_delay)
  end

  defp end_flow_delay("ivr", _), do: []
  defp end_flow_delay(_, delay), do: [%{type: "end", delay: delay, label: "#{delay}h"}]

  defp flow_retries(survey, mode, 0) do
    flow_retries_with_fallback(survey, mode)
  end

  defp flow_retries(survey, mode, _) do
    fallback_delay = survey |> Survey.fallback_delay() |> minutes_to_hours()
    flow_retries_with_fallback(survey, mode, fallback_delay)
  end

  defp flow_retries_with_fallback(survey, mode, fallback_delay \\ 0) do
    delay_hours =
      survey
      |> Survey.retries_configuration(mode)
      |> Enum.map(fn retry_minutes -> Kernel.round(retry_minutes / 60) end)

    [
      fallback_delay |> flow_retry(mode)
      | delay_hours |> Enum.map(fn retry_hour -> flow_retry(retry_hour, mode) end)
    ]
  end

  defp flow_retry(0, mode), do: %{delay: 0, type: mode}

  defp flow_retry(delay_hours, mode),
    do: %{delay: delay_hours, label: "#{delay_hours}h", type: mode}

  defp minutes_to_hours(minutes), do: Kernel.round(minutes / 60)
end
