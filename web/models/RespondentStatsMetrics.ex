defmodule Prometheus.RespondentStatsMetrics do
  use Prometheus.Collector

  alias Ask.Repo

  def collect_mf(_registry, callback) do
    respondent_stats = Repo.all(Ask.RespondentStats)
    callback.(create_gauge(
      :surveda_respondents,
      "The respondent stats table metrics",
      respondent_stats
             ))
    :ok
  end

  def collect_metrics(:surveda_respondents, data) do
    result_list = reject_unused_keys(data)
                  |> format_list
    Prometheus.Model.gauge_metrics(
      Enum.reject(
        result_list,
        fn element ->
          {_, count} = element
          count == 0
        end
      )
    )
  end

  defp create_gauge(name, help, data) do
    Prometheus.Model.create_mf(name, help, :gauge, __MODULE__, data)
  end

  defp reject_unused_keys(data) do
    for row <- data, into: [] do
      Map.to_list(row)
      |> Enum.reject(
           fn element ->
             {key, _} = element
             key == :__meta__ || key == :__struct__ || key == :survey
           end
         )
      |> format_row
    end
  end

  defp format_list(list) do
    for row <- list do
      count = row[:count]
      {List.keydelete(row, :count, 0), count}
    end
  end

  defp format_row(row) do
    Enum.map(
      row, fn (element) ->
        {key, value} = element
        {key, value} = parse_mode(key, value)
        {key, string_to_charlist(value)}
      end
    )
  end

  defp parse_mode(key, value) when key == :mode and value != "" do
    {key, Poison.decode!(value) |> Enum.join(",")}
  end

  defp parse_mode(key, value), do: {key, value}

  defp string_to_charlist(string) do
    if String.valid?(string) do
      String.to_charlist(string)
    end
    string
  end
end
