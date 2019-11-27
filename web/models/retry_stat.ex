defmodule Ask.RetryStat do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Ask.{RetryStat, Repo}
  alias Ask.Ecto.Type.JSON

  schema "retry_stats" do
    field(:attempt, :integer)
    field(:count, :integer)
    field(:mode, JSON)
    field(:retry_time, :string)
    belongs_to(:survey, Ask.Survey)

    timestamps()
  end

  def changeset(%RetryStat{} = retry_stat, attrs) do
    retry_stat
    |> cast(attrs, [:mode, :attempt, :retry_time, :count, :survey_id])
    |> validate_required([:mode, :attempt, :retry_time, :count, :survey_id])
    |> unique_constraint(:retry_stats_mode_attempt_retry_time_survey_id_index)
  end

  def transition!(substract_filter, increase_filter) do
    case Ecto.Multi.new()
         |> Ecto.Multi.update_all(
           :update_all,
           substract_query(substract_filter),
           []
         )
         |> Ecto.Multi.run(:substracted, fn result -> substracted(result) end)
         |> Ecto.Multi.insert(
           :insert_all,
           add_struct(increase_filter),
           on_conflict: [inc: [count: 1]]
         )
         |> Repo.transaction() do
      {:ok, _} ->
        {:ok}

      _ ->
        {:error}
    end
  end

  defp substracted(%{update_all: {0, _}}), do: {:error, nil}
  defp substracted(_), do: {:ok, nil}

  defp add_struct(%{attempt: attempt, mode: mode, retry_time: retry_time, survey_id: survey_id}),
    do: %RetryStat{
      attempt: attempt,
      count: 1,
      mode: mode,
      retry_time: retry_time,
      survey_id: survey_id
    }

  defp substract_query(%{
         attempt: attempt,
         mode: mode,
         retry_time: retry_time,
         survey_id: survey_id
       }),
       do:
         from(
           s in RetryStat,
           where:
             s.attempt == ^attempt and s.mode == ^mode and s.retry_time == ^retry_time and
               s.survey_id == ^survey_id and s.count > 0,
           update: [inc: [count: -1]]
         )

  def add!(filter) do
    {:ok, _} =
      Repo.insert(
        add_struct(filter),
        on_conflict: [inc: [count: 1]]
      )

    {:ok}
  end

  def subtract!(filter) do
    case substract_query(filter)
         |> Repo.update_all([]) do
      {0, _} ->
        {:error}

      {_, _} ->
        {:ok}
    end
  end

  def stats(%{survey_id: survey_id}),
    do:
      Repo.all(
        from(
          rs in RetryStat,
          where: rs.count > 0 and rs.survey_id == ^survey_id
        )
      )

  def count(stats, %{overdue: true} = filter), do: stats |> count_overdue(filter)

  def count(stats, %{attempt: filter_attempt, mode: filter_mode, retry_time: filter_retry_time}),
    do:
      Enum.find(stats, fn %RetryStat{attempt: attempt, retry_time: retry_time, mode: mode} ->
        attempt == filter_attempt and retry_time == filter_retry_time and mode == filter_mode
      end)
      |> count_stat

  defp count_overdue(stats, %{
         attempt: filter_attempt,
         mode: filter_mode,
         retry_time: filter_retry_time
       }),
       do:
         stats
         |> Enum.filter(fn %RetryStat{attempt: attempt, retry_time: retry_time, mode: mode} ->
           attempt == filter_attempt and retry_time != "" and retry_time <= filter_retry_time and
             mode == filter_mode
         end)
         |> Enum.map(fn stat -> stat |> count_stat() end)
         |> Enum.sum()

  defp count_stat(nil), do: 0
  defp count_stat(stat), do: stat.count

  def retry_time(timeout_at), do: Timex.format!(timeout_at, "%Y%0m%0d%H", :strftime)
end
