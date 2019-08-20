defmodule Prometheus.RespondentStatsMetrics do
  use Prometheus.Collector

  alias Ask.Repo

  def collect_mf(_registry, callback) do
    respondent_stats_query = "select rs.* from respondent_stats rs"
    query_results = Repo.query!(respondent_stats_query)
    columns = query_results.columns|> Enum.map(fn(column_name) -> String.to_charlist(column_name) end)
    rows = query_results.rows |> Enum.map(fn(row) -> formatRow(row) end)
    result_list =  Enum.map(rows, fn row ->
                                      columns
                                      |> Enum.zip(row)
                                      |> Enum.into([])
                            end)
    callback.(create_gauge(
              :surveda_respondents,
              "The respondent stats table metrics",
              result_list
             ))
    :ok
  end

  def collect_metrics(:surveda_respondents, memory) do
    Prometheus.Model.gauge_metrics(memory)
  end

  defp create_gauge(name, help, data) do
    Prometheus.Model.create_mf(name, help, :gauge, __MODULE__, data)
  end

  defp formatRow(row) do
    Enum.map(row, fn (element) ->
                  if String.valid?(element) do
                    String.to_charlist(element)
                  else
                    element
                  end
              end)
  end

end