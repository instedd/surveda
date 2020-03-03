defmodule Ask.Stats do
  @behaviour Ecto.Type
  alias __MODULE__

  defstruct total_received_sms: 0,
            total_sent_sms: 0,
            total_call_time: nil,
            total_call_time_seconds: nil,
            call_durations: %{},
            attempts: nil,
            last_call_started: false

  def type, do: :longtext

  def cast(%Stats{} = stats) do
    {:ok, stats}
  end

  def cast(%{
        total_received_sms: total_received_sms,
        total_sent_sms: total_sent_sms,
        total_call_time: total_call_time,
        total_call_time_seconds: total_call_time_seconds,
        call_durations: call_durations,
        attempts: attempts,
        last_call_started: last_call_started
      }) do
    {:ok,
     %Stats{
       total_received_sms: total_received_sms,
       total_sent_sms: total_sent_sms,
       total_call_time: total_call_time,
       total_call_time_seconds: total_call_time_seconds,
       call_durations: call_durations || %{},
       attempts: attempts,
       last_call_started: last_call_started || false
     }}
  end

  def cast(%{} = map) do
    cast(%{
      total_received_sms: map["total_received_sms"],
      total_sent_sms: map["total_sent_sms"],
      total_call_time: map["total_call_time"],
      total_call_time_seconds: map["total_call_time_seconds"],
      call_durations: map["call_durations"],
      attempts: map["attempts"],
      last_call_started: map["last_call_started"]
    })
  end

  def cast(nil), do: {:ok, %Stats{}}
  def cast(_), do: :error

  def load(string) when is_binary(string), do: cast(Poison.decode!(string))
  def load(_), do: :error

  def dump(%Stats{} = stats), do: Poison.encode(stats)
  def dump(_), do: :error

  def total_received_sms(%Stats{total_received_sms: count}), do: count

  def total_received_sms(%Stats{} = stats, count) do
    %{stats | total_received_sms: count}
  end

  def total_sent_sms(%Stats{total_sent_sms: count}), do: count

  def total_sent_sms(%Stats{} = stats, count) do
    %{stats | total_sent_sms: count}
  end

  def total_call_time(stats),
    do: "#{total_call_time_minutes(stats)}m #{total_call_time_minutes_rem(stats)}s"

  defp total_call_time_minutes(stats), do: (total_call_time_seconds(stats) / 60) |> Kernel.trunc()
  defp total_call_time_minutes_rem(stats), do: rem(total_call_time_seconds(stats), 60)

  # We should eventually decide to migrate all the ways to store call durations to a single, unified one
  defp grouped_calls_time(%Stats{total_call_time: nil, total_call_time_seconds: nil}), do: 0

  defp grouped_calls_time(%Stats{total_call_time: minutes, total_call_time_seconds: nil}),
    do: (minutes * 60) |> Kernel.trunc()

  defp grouped_calls_time(total_call_time_seconds: nil), do: 0

  defp grouped_calls_time(%Stats{total_call_time_seconds: seconds}) when seconds != nil,
    do: seconds

  def total_call_time_seconds(stats), do:
    grouped_calls_time(stats) + individual_calls_time(stats)

  defp individual_calls_time(%{call_durations: call_durations}), do:
    call_durations |> Enum.reduce(0, fn {_call_id, duration}, acum -> acum + duration end)
  defp individual_calls_time(_stats), do: 0

  def with_call_time(%{call_durations: call_durations} = stats, call_id, seconds) do
    new_durations = call_durations |> Map.put(call_id, seconds)
    %{stats | call_durations: new_durations}
  end

  def add_received_sms(%Stats{total_received_sms: total} = stats, count \\ 1),
    do: %{stats | total_received_sms: total + count}

  def add_sent_sms(%Stats{total_sent_sms: total} = stats, count \\ 1),
    do: %{stats | total_sent_sms: total + count}

  def attempts(%Stats{attempts: nil}, :sms), do: 0
  def attempts(%Stats{attempts: %{"sms" => total}}, :sms), do: total
  def attempts(%Stats{attempts: _}, :sms), do: 0

  def attempts(%Stats{attempts: nil}, :ivr), do: 0
  def attempts(%Stats{attempts: %{"ivr" => total}}, :ivr), do: total
  def attempts(%Stats{attempts: _}, :ivr), do: 0

  def attempts(%Stats{attempts: nil}, :mobileweb), do: 0
  def attempts(%Stats{attempts: %{"mobileweb" => total}}, :mobileweb), do: total
  def attempts(%Stats{attempts: _}, :mobileweb), do: 0

  def attempts(%Stats{} = stats, :all),
    do: attempts(stats, :sms) + attempts(stats, :ivr) + attempts(stats, :mobileweb)

  def add_attempt(stats, mode) do
    stats = add_attempt_internal(stats, mode)
    case mode do
      :ivr -> stats |> Map.put(:last_call_started, false)
      _ -> stats
    end
  end

  defp add_attempt_internal(%Stats{attempts: nil} = stats, :sms), do: %{stats | attempts: %{"sms" => 1}}

  defp add_attempt_internal(%Stats{attempts: %{"sms" => total} = attempts} = stats, :sms),
    do: %{stats | attempts: %{attempts | "sms" => total + 1}}

  defp add_attempt_internal(%Stats{attempts: attempts} = stats, :sms),
    do: %{stats | attempts: Map.put(attempts, "sms", 1)}

  defp add_attempt_internal(%Stats{attempts: nil} = stats, :ivr), do: %{stats | attempts: %{"ivr" => 1}}

  defp add_attempt_internal(%Stats{attempts: %{"ivr" => total} = attempts} = stats, :ivr),
    do: %{stats | attempts: %{attempts | "ivr" => total + 1}}

  defp add_attempt_internal(%Stats{attempts: attempts} = stats, :ivr),
    do: %{stats | attempts: Map.put(attempts, "ivr", 1)}

  defp add_attempt_internal(%Stats{attempts: nil} = stats, :mobileweb),
    do: %{stats | attempts: %{"mobileweb" => 1}}

  defp add_attempt_internal(%Stats{attempts: %{"mobileweb" => total} = attempts} = stats, :mobileweb),
    do: %{stats | attempts: %{attempts | "mobileweb" => total + 1}}

  defp add_attempt_internal(%Stats{attempts: attempts} = stats, :mobileweb),
    do: %{stats | attempts: Map.put(attempts, "mobileweb", 1)}

  def with_last_call_attempted(stats), do: stats |> Map.put(:last_call_started, true)
end
