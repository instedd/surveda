defmodule Ask.Stats do
  @behaviour Ecto.Type
  alias __MODULE__

  defstruct total_received_sms: 0, total_sent_sms: 0, total_call_time: 0, attempts: nil

  def type, do: :longtext

  def cast(%Stats{} = stats) do
    {:ok, stats}
  end

  def cast(%{total_received_sms: total_received_sms, total_sent_sms: total_sent_sms, total_call_time: total_call_time, attempts: attempts}) do
    {:ok, %Stats{
      total_received_sms: total_received_sms,
      total_sent_sms: total_sent_sms,
      total_call_time: total_call_time,
      attempts: attempts
    }}
  end
  def cast(%{} = map) do
    cast(%{
      total_received_sms: map["total_received_sms"],
      total_sent_sms: map["total_sent_sms"],
      total_call_time: map["total_call_time"],
      attempts: map["attempts"]
    })
  end
  def cast(nil), do: {:ok, %Stats{}}
  def cast(_), do: :error

  def load(string) when is_binary(string), do: cast(Poison.decode!(string))
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

  def add_received_sms(%Stats{total_received_sms: total} = stats, count \\ 1) do
    %{stats | total_received_sms: total + count}
  end

  def add_sent_sms(%Stats{total_sent_sms: total} = stats, count \\ 1) do
    %{stats | total_sent_sms: total + count}
  end

  def attempts(%Stats{attempts: nil }, :sms) do
    0
  end
  def attempts(%Stats{attempts: %{ "sms" => total }}, :sms) do
    total
  end
  def attempts(%Stats{attempts: _}, :sms) do
    0
  end

  def attempts(%Stats{attempts: nil }, :ivr) do
    0
  end
  def attempts(%Stats{attempts: %{ "ivr" => total }}, :ivr) do
    total
  end
  def attempts(%Stats{attempts: _}, :ivr) do
    0
  end

  def attempts(%Stats{attempts: nil }, :mobileweb) do
    0
  end
  def attempts(%Stats{attempts: %{ "mobileweb" => total }}, :mobileweb) do
    total
  end
  def attempts(%Stats{attempts: _}, :mobileweb) do
    0
  end

  def attempts(%Stats{} = stats, :all) do
    attempts(stats, :sms) + attempts(stats, :ivr) + attempts(stats, :mobileweb)
  end

  def add_attempt(%Stats{attempts: nil} = stats, :sms) do
    %{stats | attempts: %{ "sms" => 1 }}
  end
  def add_attempt(%Stats{attempts: %{ "sms" => total } = attempts } = stats, :sms) do
    %{stats | attempts: %{attempts | "sms" => total + 1}}
  end
  def add_attempt(%Stats{attempts: attempts} = stats, :sms) do
    %{stats | attempts: Map.put(attempts, "sms", 1)}
  end

  def add_attempt(%Stats{attempts: nil} = stats, :ivr) do
    %{stats | attempts: %{ "ivr" => 1 }}
  end
  def add_attempt(%Stats{attempts: %{ "ivr" => total } = attempts } = stats, :ivr) do
    %{stats | attempts: %{attempts | "ivr" => total + 1}}
  end
  def add_attempt(%Stats{attempts: attempts} = stats, :ivr) do
    %{stats | attempts: Map.put(attempts, "ivr", 1)}
  end

  def add_attempt(%Stats{attempts: nil} = stats, :mobileweb) do
    %{stats | attempts: %{ "mobileweb" => 1 }}
  end
  def add_attempt(%Stats{attempts: %{ "mobileweb" => total } = attempts } = stats, :mobileweb) do
    %{stats | attempts: %{attempts | "mobileweb" => total + 1}}
  end
  def add_attempt(%Stats{attempts: attempts} = stats, :mobileweb) do
    %{stats | attempts: Map.put(attempts, "mobileweb", 1)}
  end
end
