defmodule Ask.RespondentsFilter do
  import Ecto.Query
  defstruct [:disposition, :since, :state, :mode]
  @date_format_string "{YYYY}-{0M}-{0D}"

  def parse(q) do
    %__MODULE__{}
    |> put_disposition(extract(q, "disposition"))
    |> put_state(extract(q, "state"))
    |> parse_mode(extract(q, "mode"))
    |> parse_since(extract(q, "since"))
  end

  def put_disposition(filter, disposition) do
    Map.put(filter, :disposition, disposition)
  end

  def put_state(filter, state) do
    Map.put(filter, :state, state)
  end

  def parse_mode(filter, "mobile web") do
    Map.put(filter, :mode, "mobileweb")
  end

  def parse_mode(filter, mode) do
    Map.put(filter, :mode, mode)
  end

  def date_format_string(), do: @date_format_string

  def empty?(%__MODULE__{disposition: nil, since: nil, state: nil, mode: nil}), do: true
  def empty?(%__MODULE__{}), do: false

  @doc """
  By putting since directly (without parsing it) we're trying to cover the case where Surveda is
  being used by external services like SurvedaOnaConnector
  Before the repondents filter module existed, the "since" url param received in the respondent
  controller was being applied directly. So the understanding of the received date format string
  was delegated to Ecto
  See: https://github.com/instedd/surveda-ona-connector
  Details: lib/surveda_ona_connector/runtime/surveda_client.ex#L58-L66
  """
  def put_since(filter, since) do
    Map.put(filter, :since, since)
  end

  def parse_since(filter, since) do
    case Timex.parse(since, @date_format_string) do
      {:ok, parsed} -> Map.put(filter, :since, parsed)
      _ -> filter
    end
  end

  defp extract(q, key) do
    {:ok, regex} = Regex.compile("(^|[ ])#{key}:(?<#{key}>(\"[^\"]+\")|([^ ]+))")

    case Regex.named_captures(regex, q) do
      %{^key => value} -> String.trim(value, "\"") |> String.downcase()
      _ -> nil
    end
  end

  def filter_where(filter, options \\ []) do
    optimized = Keyword.get(options, :optimized, false)
    filter = Map.from_struct(filter)

    Enum.reduce(filter, dynamic(true), fn
      {:disposition, value}, dynamic when value != nil ->
        if optimized do
          dynamic([_, r], ^dynamic and r.disposition == ^value)
        else
          dynamic([r], ^dynamic and r.disposition == ^value)
        end

      {:since, value}, dynamic when value != nil ->
        if optimized do
          dynamic([_, r], ^dynamic and r.updated_at > ^value)
        else
          dynamic([r], ^dynamic and r.updated_at > ^value)
        end

      {:state, value}, dynamic when value != nil ->
        if optimized do
          dynamic([_, r], ^dynamic and r.state == ^value)
        else
          dynamic([r], ^dynamic and r.state == ^value)
        end

      # Test that the value is in the mode sequence
      # SQL equivalence: r.mode LIKE '%"<value>"%'
      {:mode, value}, dynamic when value != nil ->
        if optimized do
          dynamic([_, r], ^dynamic and like(r.mode, fragment("concat('%\"', ?, '\"%')", ^value)))
        else
          dynamic([r], ^dynamic and like(r.mode, fragment("concat('%\"', ?, '\"%')", ^value)))
        end

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end
end
