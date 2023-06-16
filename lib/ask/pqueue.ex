# A basic priority queue list. Items are inserted with a priority (high, normal
# or low).
defmodule Ask.PQueue do
  @type t :: map()

  @enforce_keys [:high, :normal, :low]
  defstruct [:high, :normal, :low]

  @spec new() :: t
  def new() do
    %Ask.PQueue{high: [], normal: [], low: []}
  end

  @spec push(t, any, :high | :normal | :low) :: t
  def push(queue, item, priority) do
    case priority do
      :high ->
        Map.put(queue, :high, [item | queue.high])
      :normal ->
        Map.put(queue, :normal, [item | queue.normal])
      :low ->
        Map.put(queue, :low, [item | queue.low])
    end
  end

  @spec pop(t) :: {t, any | nil}
  def pop(queue) do
    cond do
      length(queue.high) > 0 ->
        [item | tail] = Enum.reverse(queue.high)
        {Map.put(queue, :high, Enum.reverse(tail)), item}

      length(queue.normal) > 0 ->
        [item | tail] = Enum.reverse(queue.normal)
        {Map.put(queue, :normal, Enum.reverse(tail)), item}

      length(queue.low) > 0 ->
        [item | tail] = Enum.reverse(queue.low)
        {Map.put(queue, :low, Enum.reverse(tail)), item}

      true ->
        {queue, nil}
    end
  end

  @spec each(t, (any -> any)) :: :ok
  def each(queue, callback) do
    Enum.each(queue.high, callback)
    Enum.each(queue.normal, callback)
    Enum.each(queue.low, callback)
  end

  @spec delete(t, (any -> boolean)) :: t
  def delete(queue, callback) do
    cond do
      index = Enum.find_index(queue.high, callback) ->
        Map.put(queue, :high, List.delete_at(queue.high, index))

      index = Enum.find_index(queue.normal, callback) ->
        Map.put(queue, :normal, List.delete_at(queue.normal, index))

      index = Enum.find_index(queue.low, callback) ->
        Map.put(queue, :low, List.delete_at(queue.low, index))

      true ->
        queue
    end
  end

  @spec any?(t, (any -> boolean)) :: boolean
  def any?(queue, callback) do
    cond do
      Enum.any?(queue.high, callback) -> true
      Enum.any?(queue.normal, callback) -> true
      Enum.any?(queue.low, callback) -> true
      true -> false
    end
  end

  @spec empty?(t) :: boolean
  def empty?(%{high: [], low: [], normal: []}), do: true
  def empty?(_), do: false

  @spec len(t) :: non_neg_integer
  def len(queue) do
    length(queue.high) + length(queue.normal) + length(queue.low)
  end

  @spec len(t, :high | :normal | :low) :: non_neg_integer
  def len(queue, :high), do: length(queue.high)
  def len(queue, :normal), do: length(queue.normal)
  def len(queue, :low), do: length(queue.low)
end
