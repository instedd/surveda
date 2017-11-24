defmodule Ask.Stats do
  @behaviour Ecto.Type
  alias __MODULE__

  defstruct total_received_sms: 0, total_sent_sms: 0, total_call_time: 0, current_call_first_interaction_time: nil, current_call_last_interaction_time: nil

  def type, do: :longtext

  def cast(%Stats{} = stats) do
    {:ok, stats}
  end

  def cast(%{current_call_first_interaction_time: time} = stats) when is_binary(time) do
    {:ok, time, _} = time |> DateTime.from_iso8601
    cast(%{stats | current_call_first_interaction_time: time})
  end
  def cast(%{current_call_last_interaction_time: time} = stats) when is_binary(time) do
    {:ok, time, _} = time |> DateTime.from_iso8601
    cast(%{stats | current_call_last_interaction_time: time})
  end
  def cast(%{total_received_sms: total_received_sms, total_sent_sms: total_sent_sms, total_call_time: total_call_time, current_call_first_interaction_time: current_call_first_interaction_time, current_call_last_interaction_time: current_call_last_interaction_time}) do
    {:ok, %Stats{
      total_received_sms: total_received_sms,
      total_sent_sms: total_sent_sms,
      total_call_time: total_call_time,
      current_call_first_interaction_time: current_call_first_interaction_time,
      current_call_last_interaction_time: current_call_last_interaction_time
    }}
  end
  def cast(%{} = map) do
    cast(%{
      total_received_sms: map["total_received_sms"],
      total_sent_sms: map["total_sent_sms"],
      total_call_time: map["total_call_time"],
      current_call_first_interaction_time: map["current_call_first_interaction_time"],
      current_call_last_interaction_time: map["current_call_last_interaction_time"]
    })
  end
  def cast(nil), do: {:ok, %Stats{}}
  def cast(_), do: :error

  def load(string) when is_binary(string), do: cast(Poison.decode!(string))
  def load(nil), do: {:ok, %Stats{}}
  def load(_), do: :error

  def dump(%Stats{}=stats), do: Poison.encode(stats)
  def dump(_), do: :error

  def total_received_sms(%Stats{total_received_sms: count}), do: count
  def total_received_sms(%Stats{} = stats, count) do
    %{stats | total_received_sms: count}
  end

  def total_sent_sms(%Stats{total_sent_sms: count}), do: count
  def total_sent_sms(%Stats{} = stats, count) do
    %{stats | total_sent_sms: count}
  end

  def total_call_time(%Stats{total_call_time: count}), do: count
  def total_call_time(%Stats{} = stats, count) do
    %{stats | total_call_time: count}
  end

  def first_interaction_time(%Stats{current_call_first_interaction_time: date_time}), do: date_time
  def first_interaction_time(%Stats{} = stats, date_time) do
    %{stats | current_call_first_interaction_time: date_time}
  end

  def last_interaction_time(%Stats{current_call_last_interaction_time: date_time}), do: date_time
  def last_interaction_time(%Stats{} = stats, date_time) do
    %{stats | current_call_last_interaction_time: date_time}
  end

  def add_received_sms(%Stats{total_received_sms: total} = stats, count \\ 1) do
    %{stats | total_received_sms: total + count}
  end

  def add_sent_sms(%Stats{total_sent_sms: total} = stats, count \\ 1) do
    %{stats | total_sent_sms: total + count}
  end

  def set_interaction_time(%Stats{current_call_first_interaction_time: nil} = stats, date_time) do
    first_interaction_time(stats, date_time)
  end
  def set_interaction_time(%Stats{} = stats, date_time) do
    last_interaction_time(stats, date_time)
  end

  def add_total_call_time(%Stats{current_call_first_interaction_time: nil} = stats), do: stats
  def add_total_call_time(%Stats{current_call_last_interaction_time: nil} = stats), do: stats
  def add_total_call_time(%Stats{current_call_first_interaction_time: first_interaction_time, current_call_last_interaction_time: last_interaction_time} = stats) do
    stats
    |> total_call_time(DateTime.diff(last_interaction_time, first_interaction_time) / 60)
    |> first_interaction_time(nil)
    |> last_interaction_time(nil)
  end
end
