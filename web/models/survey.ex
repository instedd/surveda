defmodule Ask.Survey do
  use Ask.Web, :model

  @max_int 2147483647

  schema "surveys" do
    field :name, :string
    field :mode, Ask.Ecto.Type.JSON
    field :state, :string, default: "not_ready" # not_ready, ready, pending, active, completed
    field :cutoff, :integer
    field :respondents_count, :integer, virtual: true
    field :schedule_day_of_week, Ask.DayOfWeek, default: Ask.DayOfWeek.never
    field :schedule_start_time, Ecto.Time
    field :schedule_end_time, Ecto.Time
    field :timezone, :string
    field :started_at, Timex.Ecto.DateTime
    field :sms_retry_configuration, :string
    field :ivr_retry_configuration, :string
    field :quota_vars, Ask.Ecto.Type.JSON, default: []

    many_to_many :channels, Ask.Channel, join_through: Ask.SurveyChannel, on_replace: :delete
    has_many :respondents, Ask.Respondent
    has_many :quota_buckets, Ask.QuotaBucket

    belongs_to :project, Ask.Project
    belongs_to :questionnaire, Ask.Questionnaire

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :project_id, :mode, :questionnaire_id, :state, :cutoff, :respondents_count, :schedule_day_of_week, :schedule_start_time, :schedule_end_time, :timezone, :sms_retry_configuration, :ivr_retry_configuration, :started_at])
    |> validate_required([:project_id, :state, :schedule_start_time, :schedule_end_time, :timezone])
    |> foreign_key_constraint(:project_id)
    |> validate_from_less_than_to
    |> validate_number(:cutoff, greater_than: 0, less_than: @max_int)
  end

  def update_state(changeset) do
    state = get_field(changeset, :state)
    mode = get_field(changeset, :mode)
    questionnaire_id = get_field(changeset, :questionnaire_id)
    respondents_count = get_field(changeset, :respondents_count)

    schedule = get_field(changeset, :schedule_day_of_week)
    [ _ | values ] = Map.values(schedule)
    schedule_completed = Enum.reduce(values, fn (x, acc) -> acc || x end)

    channels = get_field(changeset, :channels)
    ready = questionnaire_id && respondents_count && respondents_count > 0
      && length(channels) > 0 && schedule_completed && mode && validate_retry_attempts_configuration(changeset)
      && Enum.all?(mode, fn(m) -> Enum.any?(channels, fn(c) -> m == c.type end) end)

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

  def validate_retry_attempts_configuration(changeset) do
    sms_retry_configuration = get_field(changeset, :sms_retry_configuration)
    ivr_retry_configuration = get_field(changeset, :ivr_retry_configuration)
    valid = valid_retry_configuration?(sms_retry_configuration) && valid_retry_configuration?(ivr_retry_configuration)
    valid
  end

  def valid_retry_configuration?(retry_configuration) do
    valid = !retry_configuration || Enum.all?(String.split(retry_configuration), fn s -> Regex.match?(~r/^\d+[mdh]$/, s) end)
    valid
  end

  def retries_configuration(survey, mode) do
    retries = case mode do
      "sms" -> survey.sms_retry_configuration
      "ivr" -> survey.ivr_retry_configuration
      _ -> nil
    end

    parse_retries(retries)
  end

  def primary_channel(survey) do
    case survey.mode do
      [mode | _] -> channel(survey, mode)
      _ -> nil
    end
  end

  def fallback_channel(survey) do
    case survey.mode do
      [_, mode] -> channel(survey, mode)
      _ -> nil
    end
  end

  defp channel(survey, mode) do
    survey.channels |> Enum.find(fn c -> c.type == mode end)
  end

  defp parse_retries(nil), do: []

  defp parse_retries(retries) do
    retries
    |> String.split
    |> Enum.map(&parse_retry_item(&1))
    |> Enum.reject(fn x -> x == 0 end)
  end

  defp parse_retry_item(value) do
    case Integer.parse(value) do
      :error -> 0
      {value, type} ->
        case type do
          "m" -> value
          "h" -> value * 60
          "d" -> value * 60 * 24
          _ -> 0
        end
    end
  end
end
