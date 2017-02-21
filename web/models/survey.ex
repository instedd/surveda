defmodule Ask.Survey do
  use Ask.Web, :model

  @max_int 2147483647

  schema "surveys" do
    field :name, :string
    field :mode, Ask.Ecto.Type.JSON
    field :state, :string, default: "not_ready" # not_ready, ready, pending, running, completed, cancelled
    field :cutoff, :integer
    field :count_partial_results, :boolean, default: false
    field :respondents_count, :integer, virtual: true
    field :schedule_day_of_week, Ask.DayOfWeek, default: Ask.DayOfWeek.never
    field :schedule_start_time, Ecto.Time
    field :schedule_end_time, Ecto.Time
    field :timezone, :string
    field :started_at, Timex.Ecto.DateTime
    field :sms_retry_configuration, :string
    field :ivr_retry_configuration, :string
    field :fallback_delay, :string
    field :quota_vars, Ask.Ecto.Type.JSON, default: []
    field :quotas, Ask.Ecto.Type.JSON, virtual: true
    field :comparisons, Ask.Ecto.Type.JSON, default: []

    has_many :respondent_groups, Ask.RespondentGroup
    has_many :respondents, Ask.Respondent
    has_many :quota_buckets, Ask.QuotaBucket, on_replace: :delete
    many_to_many :questionnaires, Ask.Questionnaire, join_through: Ask.SurveyQuestionnaire, on_replace: :delete

    belongs_to :project, Ask.Project

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :project_id, :mode, :state, :cutoff, :respondents_count, :schedule_day_of_week, :schedule_start_time, :schedule_end_time, :timezone, :sms_retry_configuration, :ivr_retry_configuration, :fallback_delay, :started_at, :quotas, :quota_vars, :comparisons, :count_partial_results])
    |> validate_required([:project_id, :state, :schedule_start_time, :schedule_end_time, :timezone])
    |> foreign_key_constraint(:project_id)
    |> validate_from_less_than_to
    |> validate_number(:cutoff, greater_than: 0, less_than: @max_int)
    |> translate_quotas
  end

  defp translate_quotas(changeset) do
    if quotas = get_field(changeset, :quotas) do
      delete_change(changeset, :quotas)
      |> change(quota_vars: quotas["vars"])
      |> put_assoc(:quota_buckets, Ask.QuotaBucket.build_changeset(changeset.data, quotas["buckets"]))
      |> cast_assoc(:quota_buckets)
    else
      changeset
    end
  end

  def update_state(changeset) do
    ready =
      mode_ready?(changeset) &&
      schedule_ready?(changeset) &&
      retry_attempts_ready?(changeset) &&
      fallback_delay_ready?(changeset) &&
      comparisons_ready?(changeset) &&
      questionnaires_ready?(changeset) &&
      respondent_groups_ready?(changeset)

    state = get_field(changeset, :state)

    cond do
      state == "not_ready" && ready ->
        change(changeset, state: "ready")
      state == "ready" && !ready ->
        change(changeset, state: "not_ready")
      true ->
        changeset
    end
  end

  def validate_from_less_than_to(changeset) do
    from = get_field(changeset, :schedule_start_time)
    to = get_field(changeset, :schedule_end_time)

    cond do
      from && to && from >= to ->
        add_error(changeset, :from, "has to be less than the To")
      true ->
        changeset
    end
  end

  defp questionnaires_ready?(changeset) do
    questionnaires = get_field(changeset, :questionnaires)
    length(questionnaires) > 0
  end

  defp schedule_ready?(changeset) do
    schedule = get_field(changeset, :schedule_day_of_week)

    [ _ | values ] = Map.values(schedule)
    Enum.reduce(values, fn (x, acc) -> acc || x end)
  end

  defp mode_ready?(changeset) do
    mode = get_field(changeset, :mode)
    mode && length(mode) > 0
  end

  def comparisons_ready?(changeset) do
    comparisons = get_field(changeset, :comparisons)
    if comparisons && length(comparisons) > 0 do
      sum = comparisons
      |> Enum.map(&Map.get(&1, "ratio", 0))
      |> Enum.sum
      sum == 100
    else
      true
    end
  end

  defp respondent_groups_ready?(changeset) do
    mode = get_field(changeset, :mode)
    respondent_groups = get_field(changeset, :respondent_groups)
    respondent_groups &&
      length(respondent_groups) > 0 &&
      Enum.all?(respondent_groups, &respondent_group_ready?(&1, mode))
  end

  defp respondent_group_ready?(respondent_group, mode) do
    channels = respondent_group.channels
    Enum.all?(mode, fn(modes) ->
      Enum.all?(modes, fn(m) -> Enum.any?(channels, fn(c) -> m == c.type end) end)
    end)
  end

  defp retry_attempts_ready?(changeset) do
    sms_retry_configuration = get_field(changeset, :sms_retry_configuration)
    ivr_retry_configuration = get_field(changeset, :ivr_retry_configuration)
    valid_retry_configurations?(sms_retry_configuration) && valid_retry_configurations?(ivr_retry_configuration)
  end

  defp fallback_delay_ready?(changeset) do
    fallback_delay = get_field(changeset, :fallback_delay)
    valid_retry_configuration?(fallback_delay)
  end

  defp valid_retry_configurations?(retry_configurations) do
    !retry_configurations || Enum.all?(String.split(retry_configurations), fn s -> valid_retry_configuration?(s) end)
  end

  defp valid_retry_configuration?(retry_configuration) do
    !retry_configuration || Regex.match?(~r/^\d+[mdh]$/, retry_configuration)
  end

  def retries_configuration(survey, mode) do
    retries = case mode do
      "sms" -> survey.sms_retry_configuration
      "ivr" -> survey.ivr_retry_configuration
      _ -> nil
    end

    parse_retries(retries)
  end

  def fallback_delay(survey) do
    if survey.fallback_delay do
      parse_retry_item(survey.fallback_delay |> String.trim, nil)
    else
      nil
    end
  end

  defp parse_retries(nil), do: []

  defp parse_retries(retries) do
    retries
    |> String.split
    |> Enum.map(&parse_retry_item(&1))
    |> Enum.reject(fn x -> x == 0 end)
  end

  defp parse_retry_item(value, on_error \\ 0) do
    case Integer.parse(value) do
      :error -> on_error
      {value, type} ->
        case type do
          "m" -> value
          "h" -> value * 60
          "d" -> value * 60 * 24
          _ -> on_error
        end
    end
  end
end
