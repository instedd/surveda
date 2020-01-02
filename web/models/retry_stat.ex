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
    field(:ivr_active, :boolean)
    has_many(:respondent, Ask.Respondent)
    belongs_to(:survey, Ask.Survey)

    timestamps()
  end

  @retry_time_format "%Y%0m%0d%H"

  def retry_time_format(), do: @retry_time_format

  def changeset(%RetryStat{} = retry_stat, attrs) do
    retry_stat
    |> cast(attrs, [:mode, :attempt, :retry_time, :ivr_active, :count, :survey_id])
    |> validate_required([:mode, :attempt, :retry_time, :ivr_active, :count, :survey_id])
    |> validate_retry_time()
    |> unique_constraint(:retry_stats_mode_attempt_retry_time_survey_id_index)
  end

  def count_changeset(%RetryStat{} = retry_stat, attrs) do
    retry_stat
    |> cast(attrs, [:mode, :attempt, :ivr_active])
    |> validate_required([:mode, :attempt, :ivr_active])
  end

  defp validate_retry_time(changeset) do
    retry_time = get_field(changeset, :retry_time)
    if not is_valid_retry_time?(retry_time) do
      add_error(changeset, :retry_time, "Retry time must be YYYYMMDDHH")
    else
      changeset
    end
  end

  defp is_valid_retry_time?(retry_time) do
    case Timex.parse(retry_time, @retry_time_format, :strftime) do
      {:ok, _} ->
        true
      {_, _} ->
        false
    end
  end

  def transition(retry_stat_id, increase_filter) do
    add_changeset = add_changeset(increase_filter)
    case retry_stat_id != nil and add_changeset.valid? do
      true ->
        case Repo.update_all(subtract_query(retry_stat_id), []) do
          {0, _} ->
            {:error, nil}

          _ ->
            Repo.insert(
              add_changeset,
              on_conflict: [inc: [count: 1]]
            )
        end
      _ ->
        {:error, nil}
    end
  end

  defp is_valid_count_filter(%{attempt: attempt, mode: mode, ivr_active: ivr_active}), do:
    RetryStat.count_changeset(%RetryStat{}, %{
      attempt: attempt,
      mode: mode,
      ivr_active: ivr_active
    }).valid?

  defp add_changeset(%{attempt: attempt, mode: mode, retry_time: retry_time, ivr_active: ivr_active, survey_id: survey_id}), do:
    RetryStat.changeset(%RetryStat{}, %{
      attempt: attempt,
      count: 1,
      mode: mode,
      retry_time: retry_time,
      ivr_active: ivr_active,
      survey_id: survey_id
    })

  defp add_changeset(_), do: RetryStat.changeset(%RetryStat{}, %{})

  defp subtract_query(retry_stat_id),
  do:
    from(
      s in RetryStat,
      where:
        s.id == ^retry_stat_id and s.count > 0,
      update: [inc: [count: -1]]
    )

  def add(filter), do:
    Repo.insert(
      add_changeset(filter),
      on_conflict: [inc: [count: 1]]
    )

  def subtract(retry_stat_id) do
    case retry_stat_id do
      nil ->
        {:error}
      _ ->
        case subtract_query(retry_stat_id)
              |> Repo.update_all([]) do
          {0, _} ->
            {:error}

          {_, _} ->
            {:ok}
        end
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

  def count(stats, filter) do
    # the stats are already filtered by survey
    case is_valid_count_filter(filter) do
      true ->
        stats |> count_valid(filter)
      _ ->
        0
    end
  end

  defp count_valid(stats, %{overdue: true} = filter), do: stats |> count_overdue(filter)

  defp count_valid(stats, %{attempt: filter_attempt, mode: filter_mode, retry_time: filter_retry_time, ivr_active: filter_ivr_active}),
    do:
      Enum.find(stats, fn %RetryStat{attempt: attempt, retry_time: retry_time, ivr_active: ivr_active, mode: mode} ->
        attempt == filter_attempt and retry_time == filter_retry_time and ivr_active == filter_ivr_active and mode == filter_mode
      end)
      |> count_stat

  defp count_valid(stats, %{attempt: filter_attempt, mode: filter_mode, ivr_active: filter_ivr_active}),
  do:
    Enum.find(stats, fn %RetryStat{attempt: attempt, ivr_active: ivr_active, mode: mode} ->
      attempt == filter_attempt and ivr_active == filter_ivr_active and mode == filter_mode
    end)
    |> count_stat

  defp count_overdue(_stats, %{ivr_active: true}), do: 0

  defp count_overdue(stats, %{
         attempt: filter_attempt,
         mode: filter_mode,
         retry_time: filter_retry_time
       }),
       do:
         stats
         |> Enum.filter(fn %RetryStat{attempt: attempt, retry_time: retry_time, mode: mode, ivr_active: ivr_active} ->
           attempt == filter_attempt and retry_time <= filter_retry_time and
             mode == filter_mode and not ivr_active
         end)
         |> Enum.map(fn stat -> stat |> count_stat() end)
         |> Enum.sum()

  defp count_stat(nil), do: 0
  defp count_stat(stat), do: stat.count

  def retry_time(nil), do: nil
  def retry_time(timeout_at), do: Timex.format!(timeout_at, @retry_time_format, :strftime)
end
