defmodule Ask.RetriesHistogram do
  alias Ask.{Survey, RetryStat, SystemTime}

  def survey_histograms(%Survey{mode: mode} = survey) do
    stats = %{survey_id: survey.id} |> RetryStat.stats()
    mode |> Enum.map(fn mode -> survey |> mode_sequence_histogram(stats, mode) end)
  end

  defp mode_sequence_histogram(%Survey{} = survey, stats, mode) do
    flow = survey |> retries_histogram_flow(mode)

    %{
      flow: flow,
      actives: retries_histogram_actives(flow, stats, mode)
    }
  end

  defp retries_histogram_actives(flow, stats, mode) do
    enhanced_flow = enhance_flow(flow)

    (get_actives(enhanced_flow, stats, mode) ++
       get_inactives(enhanced_flow, stats, mode))
    |> clean_empty_slots()
  end

  defp get_actives(enhanced_flow, stats, mode) do
    enhanced_flow
    |> Enum.map(fn %{index: index} = attempt ->
      get_active(%{
        current_attempt: attempt,
        stats: stats,
        mode: mode,
        now: SystemTime.time.now,
        next_attempt: Enum.at(enhanced_flow, index + 1)
      })
    end)
  end

  defp get_active(%{current_attempt: %{type: "end"}}) do
    nil
  end

  defp get_active(%{
         current_attempt: %{absolute_delay: absolute_delay, type: current_mode, index: index},
         stats: stats,
         mode: mode,
         now: now,
         next_attempt: next_attempt
       }) do
    next_attempt_delay = next_attempt |> attempt_delay()

    retry_time =
      if next_attempt_delay,
        do: now |> Timex.shift(hours: next_attempt_delay) |> retry_time(),
        else: nil

    count =
      count_actives(%{
        stats: stats,
        attempt: index + 1,
        mode: mode,
        current_mode: current_mode,
        retry_time: retry_time,
        next_attempt: next_attempt
      })

    %{hour: absolute_delay, respondents: count}
  end

  defp get_inactives(enhanced_flow, stats, mode) do
    enhanced_flow
    |> Enum.map(fn %{index: index} = attempt ->
      get_attempt_inactives(%{
        current_attempt: attempt,
        stats: stats,
        mode: mode,
        now: SystemTime.time.now,
        next_attempt: Enum.at(enhanced_flow, index + 1)
      })
    end)
    |> List.flatten()
  end

  defp get_attempt_inactives(%{current_attempt: %{type: "end"}}), do: []
  defp get_attempt_inactives(%{next_attempt: nil}), do: []

  defp get_attempt_inactives(%{
         current_attempt: %{absolute_delay: absolute_delay, index: index},
         stats: stats,
         mode: mode,
         now: now,
         next_attempt: %{delay: next_attempt_delay, type: next_attempt_type}
       }) do
    fill_inactives(%{
      absolute_attempt_delay: absolute_delay,
      stats: stats,
      attempt: index + 1,
      mode: mode,
      now: now,
      next_attempt_delay: next_attempt_delay,
      relative_to_now_delay: next_attempt_delay - 1,
      next_attempt_type: next_attempt_type
    })
  end

  defp fill_inactives(%{
         relative_to_now_delay: relative_to_now_delay,
         next_attempt_type: next_attempt_type
       })
       when relative_to_now_delay < 1 and next_attempt_type != "end",
       do: []

  defp fill_inactives(%{relative_to_now_delay: relative_to_now_delay, next_attempt_type: "end"})
       when relative_to_now_delay < 0,
       do: []

  defp fill_inactives(
         %{
           absolute_attempt_delay: absolute_attempt_delay,
           next_attempt_delay: next_attempt_delay,
           relative_to_now_delay: relative_to_now_delay,
           stats: stats,
           attempt: attempt,
           mode: mode,
           now: now,
           next_attempt_type: next_attempt_type
         } = params
       ) do
    retry_time = now |> Timex.shift(hours: relative_to_now_delay) |> retry_time()

    overdue =
      if next_attempt_type == "end" do
        relative_to_now_delay == 0
      else
        relative_to_now_delay == 1
      end

    count =
      stats
      |> RetryStat.count(%{
        attempt: attempt,
        mode: mode,
        retry_time: retry_time,
        ivr_active: false,
        overdue: overdue
      })

    relative_to_attempt_delay = next_attempt_delay - relative_to_now_delay

    [%{hour: absolute_attempt_delay + relative_to_attempt_delay, respondents: count}] ++
      fill_inactives(Map.put(params, :relative_to_now_delay, relative_to_now_delay - 1))
  end

  defp clean_empty_slots(slots),
    do:
      slots
      |> Enum.filter(&(!is_nil(&1)))
      |> Enum.filter(fn %{respondents: count} -> count > 0 end)

  defp attempt_delay(nil), do: nil
  defp attempt_delay(%{delay: delay}), do: delay

  defp count_actives(%{stats: stats, attempt: attempt, mode: mode, current_mode: "ivr", next_attempt: nil}),
    do:
      RetryStat.count(stats, %{
        attempt: attempt,
        mode: mode
      })

  defp count_actives(%{stats: stats, attempt: attempt, mode: mode, current_mode: "ivr", retry_time: retry_time}),
    do:
      RetryStat.count(stats, %{
        attempt: attempt,
        mode: mode,
        ivr_active: true
      }) + RetryStat.count(stats, %{
        attempt: attempt,
        mode: mode,
        retry_time: retry_time,
        ivr_active: false
      })

  defp count_actives(%{stats: stats, attempt: attempt, mode: mode, retry_time: retry_time}),
    do:
      stats
      |> RetryStat.count(%{
        attempt: attempt,
        mode: mode,
        retry_time: retry_time,
        ivr_active: false
      })

  defp enhance_flow(flow) do
    {flow, _} =
      flow
      |> Stream.with_index()
      |> Enum.map_reduce(0, fn {%{type: type, delay: delay}, idx}, acc_delay ->
        {%{type: type, delay: delay, absolute_delay: delay + acc_delay, index: idx},
         delay + acc_delay}
      end)

    flow
  end

  defp retry_time(time), do: Timex.format!(time, RetryStat.retry_time_format(), :strftime)

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
