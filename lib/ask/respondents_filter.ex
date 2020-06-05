defmodule Ask.RespondentsFilter do
  import Ecto.Query
  defstruct [:disposition, :since]
  @date_format_string "{YYYY}-{0M}-{0D}"

  def parse(q) do
    %__MODULE__{}
    |> put_disposition(extract(q, "disposition"))
    |> parse_since(extract(q, "since"))
  end

  def put_disposition(filter, disposition) do
    Map.put(filter, :disposition, disposition)
  end

  def parse_since(filter, since) do
    case Timex.parse(since, @date_format_string) do
      {:ok, parsed} -> Map.put(filter, :since, parsed)
      _ -> filter
    end
  end

  def date_format_string(), do: @date_format_string

  defp extract(q, key) do
    {:ok, exp} = Regex.compile("(^|[ ])#{key}:(?<#{key}>[^ ]+)")
    capture = Regex.named_captures(exp, q)
    if capture, do: Map.get(capture, key), else: nil
  end

  def filter_where(filter) do
    filter = Map.from_struct(filter)

    Enum.reduce(filter, dynamic(true), fn
      {:disposition, value}, dynamic when value != nil ->
        dynamic([r], ^dynamic and r.disposition == ^value)

      {:since, value}, dynamic when value != nil ->
        dynamic([r], ^dynamic and r.updated_at > ^value)

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end
end
