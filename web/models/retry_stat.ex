defmodule Ask.RetryStat do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Ask.{RetryStat, Repo, Respondent, Stats}
  alias Ask.Runtime.{Session}
  alias Ask.Ecto.Type.JSON

  schema "retry_stats" do
    field(:attempt, :integer)
    field(:count, :integer)
    field(:mode, JSON)
    field(:retry_time, :string)
    field(:ivr_active, :boolean)
    belongs_to(:survey, Ask.Survey)

    timestamps()
  end

  @retry_time_format "%Y%0m%0d%H"

  def retry_time_format(), do: @retry_time_format

  def changeset(%RetryStat{} = retry_stat, attrs) do
    retry_stat
    |> cast(attrs, [:mode, :attempt, :retry_time, :ivr_active, :count, :survey_id])
    |> validate_required([:mode, :attempt, :ivr_active, :count, :survey_id])
    |> validate_retry_time()
    |> unique_constraint(:retry_stats_mode_attempt_retry_time_survey_id_index)
  end

  defp validate_retry_time(changeset) do
    retry_time = get_field(changeset, :retry_time)
    ivr_active = get_field(changeset, :ivr_active)
    if not is_valid_retry_time?(%{retry_time: retry_time, ivr_active: ivr_active}) do
      add_error(changeset, :retry_time, "Retry time must be YYYYMMDDHH or nil if ivr_active")
    else
      changeset
    end
  end

  defp is_valid_retry_time?(%{ivr_active: true, retry_time: nil}), do: true
  defp is_valid_retry_time?(%{ivr_active: true}), do: false

  defp is_valid_retry_time?(%{ivr_active: false, retry_time: nil}), do: false
  defp is_valid_retry_time?(%{ivr_active: false, retry_time: retry_time}), do:
    is_valid_retry_time?(%{retry_time: retry_time})

  defp is_valid_retry_time?(%{retry_time: retry_time}) do
    case Timex.parse(retry_time, @retry_time_format, :strftime) do
      {:ok, _} ->
        true
      {_, _} ->
        false
    end
  end

  def transition!(subtract_filter, increase_filter) do
    add_changeset = add_changeset(increase_filter)
    case is_valid_filter(subtract_filter) and add_changeset.valid? do
      true ->
        case Repo.update_all(subtract_query(subtract_filter), []) do
          {0, _} ->
            {:error}

          _ ->
            Repo.insert(
              add_changeset,
              on_conflict: [inc: [count: 1]]
            )
            |> Tuple.delete_at(1)
        end
      _ ->
        {:error}
    end
  end

  defp is_valid_filter(filter), do:
    (filter |> add_changeset).valid?

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

  defp subtract_query(%{
    attempt: attempt,
    mode: mode,
    retry_time: nil,
    ivr_active: true,
    survey_id: survey_id
  }),
  do:
    from(
      s in RetryStat,
      where:
        s.attempt == ^attempt and s.mode == ^mode and s.ivr_active and is_nil(s.retry_time) and
          s.survey_id == ^survey_id and s.count > 0,
      update: [inc: [count: -1]]
    )

  defp subtract_query(%{
         attempt: attempt,
         mode: mode,
         retry_time: retry_time,
         ivr_active: false,
         survey_id: survey_id
       }),
       do:
         from(
           s in RetryStat,
           where:
             s.attempt == ^attempt and s.mode == ^mode and not s.ivr_active and s.retry_time == ^retry_time and
               s.survey_id == ^survey_id and s.count > 0,
           update: [inc: [count: -1]]
         )

  def add!(filter), do:
    Repo.insert(
      add_changeset(filter),
      on_conflict: [inc: [count: 1]]
    )
    |> Tuple.delete_at(1)

  def subtract!(filter) do
    case is_valid_filter(filter) do
      true ->
        case subtract_query(filter)
              |> Repo.update_all([]) do
          {0, _} ->
            {:error}

          {_, _} ->
            {:ok}
        end
      _ ->
        {:error}
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
    case is_valid_filter(Map.put(filter, :survey_id, 1)) do
      true ->
        stats |> count_valid(filter)
      _ ->
        0
    end
  end

  defp count_valid(stats, %{overdue: true} = filter), do: stats |> count_overdue(filter)

  defp count_valid(stats, %{attempt: filter_attempt, mode: filter_mode, retry_time: nil, ivr_active: true}),
  do:
    Enum.find(stats, fn %RetryStat{attempt: attempt, retry_time: retry_time, ivr_active: ivr_active, mode: mode} ->
      attempt == filter_attempt and retry_time == nil and ivr_active and mode == filter_mode
    end)
    |> count_stat

  defp count_valid(stats, %{attempt: filter_attempt, mode: filter_mode, retry_time: filter_retry_time, ivr_active: false}),
    do:
      Enum.find(stats, fn %RetryStat{attempt: attempt, retry_time: retry_time, ivr_active: ivr_active, mode: mode} ->
        attempt == filter_attempt and retry_time == filter_retry_time and not ivr_active and mode == filter_mode
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

  def increase_retry_stat(%Session{respondent: %Respondent{disposition: "queued", mode: mode, stats: stats, survey_id: survey_id}, current_mode: %Ask.Runtime.IVRMode{}}, _, _), do:
  RetryStat.add!(%{attempt: stats |> Stats.attempts(:all), mode: mode, retry_time: nil, ivr_active: true, survey_id: survey_id})
  def increase_retry_stat(%Session{respondent: %Respondent{disposition: "queued", mode: mode, stats: stats, survey_id: survey_id}}, timeout, now), do:
    RetryStat.add!(%{attempt: stats |> Stats.attempts(:all), mode: mode, retry_time: Respondent.next_timeout_lowerbound(timeout, now) |> RetryStat.retry_time(), ivr_active: false, survey_id: survey_id})
  def increase_retry_stat(%Session{respondent: %Respondent{timeout_at: nil}, current_mode: %Ask.Runtime.SMSMode{}}, _, _), do: nil
  def increase_retry_stat(%Session{respondent: %Respondent{mode: mode, stats: stats, survey_id: survey_id, retry_stat_time: retry_stat_time}, current_mode: %Ask.Runtime.SMSMode{}}, timeout, now), do:
    RetryStat.transition!(
      %{attempt: stats |> Stats.attempts(:all), mode: mode, retry_time: retry_stat_time, ivr_active: false, survey_id: survey_id},
      %{attempt: stats |> Stats.attempts(:all), mode: mode, retry_time: Respondent.next_timeout_lowerbound(timeout, now) |> RetryStat.retry_time(), ivr_active: false, survey_id: survey_id}
    )
  def increase_retry_stat(_, _, _), do: nil

  def subtract_retry_stat(%Respondent{session: %{"current_mode" => %{"mode" => "ivr"}}, mode: mode, stats: stats, survey_id: survey_id}), do:
    RetryStat.subtract!(%{attempt: stats |> Stats.attempts(:all), mode: mode, retry_time: nil, ivr_active: true, survey_id: survey_id})
  def subtract_retry_stat(%Respondent{session: %{"current_mode" => %{"mode" => _}}, mode: mode, stats: stats, survey_id: survey_id, retry_stat_time: retry_stat_time}), do:
    RetryStat.subtract!(%{attempt: stats |> Stats.attempts(:all), mode: mode, retry_time: retry_stat_time, ivr_active: false, survey_id: survey_id})
  def subtract_retry_stat(_), do: nil

end
