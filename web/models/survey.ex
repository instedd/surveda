defmodule Ask.Survey do
  use Ask.Web, :model

  alias __MODULE__
  alias Ask.{
    Schedule,
    ShortLink,
    Repo,
    Respondent,
    RespondentGroup,
    Channel,
    RespondentGroupChannel,
    QuotaBucket,
    Questionnaire,
    SurveyQuestionnaire,
    Project,
    FloipEndpoint,
    Folder
  }
  alias Ask.Runtime.{Broker, ChannelStatusServer}
  alias Ask.Ecto.Type.JSON

  @max_int 2147483647

  schema "surveys" do
    field :name, :string
    field :description, :string
    field :mode, JSON
    field :state, :string, default: "not_ready" # not_ready, ready, pending, running, terminated
    field :locked, :boolean, default: false
    field :exit_code, :integer
    field :exit_message, :string
    field :cutoff, :integer
    field :count_partial_results, :boolean, default: false
    field :schedule, Schedule, default: Schedule.default()
    field :started_at, Timex.Ecto.DateTime
    field :sms_retry_configuration, :string
    field :ivr_retry_configuration, :string
    field :mobileweb_retry_configuration, :string
    field :fallback_delay, :string
    field :quota_vars, JSON, default: []
    field :quotas, JSON, virtual: true
    field :comparisons, JSON, default: []
    field :simulation, :boolean, default: false
    field :links, :any, virtual: true
    field :floip_package_id, :string
    field :down_channels, JSON, virtual: true, default: []

    has_many :respondent_groups, RespondentGroup
    has_many :respondents, Respondent
    has_many :quota_buckets, QuotaBucket, on_replace: :delete
    many_to_many :questionnaires, Questionnaire, join_through: SurveyQuestionnaire, on_replace: :delete

    has_many :floip_endpoints, FloipEndpoint

    belongs_to :project, Project
    belongs_to :folder, Folder

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :description, :project_id, :folder_id, :mode, :state, :locked, :exit_code, :exit_message, :cutoff, :schedule, :sms_retry_configuration, :ivr_retry_configuration, :mobileweb_retry_configuration, :fallback_delay, :started_at, :quotas, :quota_vars, :comparisons, :count_partial_results, :simulation])
    |> set_floip_package_id
    |> validate_required([:project_id, :state, :schedule])
    |> foreign_key_constraint(:project_id)
    |> validate_from_less_than_to
    |> validate_number(:cutoff, greater_than_or_equal_to: 0, less_than: @max_int)
    |> translate_quotas
  end

  defp translate_quotas(changeset) do
    if quotas = get_field(changeset, :quotas) do
      delete_change(changeset, :quotas)
      |> change(quota_vars: quotas["vars"])
      |> put_assoc(:quota_buckets, QuotaBucket.build_changeset(changeset.data, quotas["buckets"]))
      |> cast_assoc(:quota_buckets)
    else
      changeset
    end
  end

  defp set_floip_package_id(changeset) do
    unless get_field(changeset, :floip_package_id) do
      change(changeset, floip_package_id: Ecto.UUID.generate)
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
      respondent_groups_ready?(changeset) &&
      mode_and_questionnaires_ready?(changeset) &&
      cutoff_ready?(changeset)

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

  def editable?(%{state: "running"}), do: false
  def editable?(%{state: "terminated"}), do: false
  def editable?(_), do: true

  def validate_from_less_than_to(changeset) do
    case Schedule.validate(get_field(changeset, :schedule)) do
      :error ->
        add_error(changeset, :from, "has to be less than the To")
      :ok ->
        changeset
    end
  end

  def packages(survey) do
    if Survey.has_floip_package?(survey) do
      [survey.floip_package_id]
    else
      []
    end
  end

  defp questionnaires_ready?(changeset) do
    questionnaires = get_field(changeset, :questionnaires)
    length(questionnaires) > 0 && Enum.all?(questionnaires, &(&1.valid))
  end

  defp schedule_ready?(changeset) do
    get_field(changeset, :schedule)
    |> Schedule.any_day_selected?
  end

  defp mode_ready?(changeset) do
    mode = get_field(changeset, :mode)
    mode && length(mode) > 0
  end

  defp mode_and_questionnaires_ready?(changeset) do
    mode = get_field(changeset, :mode)
    questionnaires = get_field(changeset, :questionnaires)

    # Check that all survey modes are present in the associated questionnaires
    mode |> Enum.all?(fn modes ->
      modes |> Enum.all?(fn mode ->
        questionnaires |> Enum.all?(fn q ->
          q.modes |> Enum.member?(mode)
        end)
      end)
    end)
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

  def cutoff_ready?(changeset) do
    quota_buckets = get_field(changeset, :quota_buckets)
    cutoff = get_field(changeset, :cutoff)

    if quota_buckets && length(quota_buckets) > 0 do
          sum = quota_buckets
          |> Enum.map(&Map.get(&1, :quota, 0))
          |> Enum.filter(& &1)
          |> Enum.sum
          sum > 0 && !exists_quota_nil?(quota_buckets)
    else
      if Map.has_key?(changeset.changes, :cutoff) do
        !is_cutoff_zero?(cutoff)
      else
        true
      end
    end
  end

  def is_cutoff_zero?(cutoff) do
    cutoff == 0
  end

  def exists_quota_nil?(quota_buckets) do
    quota_count = quota_buckets
                  |> Enum.map(&Map.get(&1, :quota))
                  |> Enum.count(&is_nil(&1))

    quota_count > 0
  end

  defp respondent_groups_ready?(changeset) do
    mode = get_field(changeset, :mode)
    respondent_groups = get_field(changeset, :respondent_groups)
    respondent_groups &&
      length(respondent_groups) > 0 &&
      Enum.all?(respondent_groups, &respondent_group_ready?(&1, mode))
  end

  defp respondent_group_ready?(respondent_group, mode) do
    channels = respondent_group.respondent_group_channels
    Enum.all?(mode, fn(modes) ->
      Enum.all?(modes, fn(m) -> Enum.any?(channels, fn(c) -> m == c.mode end) end)
    end)
  end

  defp retry_attempts_ready?(changeset) do
    sms_retry_configuration = get_field(changeset, :sms_retry_configuration)
    ivr_retry_configuration = get_field(changeset, :ivr_retry_configuration)
    mobileweb_retry_configuration = get_field(changeset, :mobileweb_retry_configuration)
    valid_retry_configurations?(sms_retry_configuration) && valid_retry_configurations?(ivr_retry_configuration) && valid_retry_configurations?(mobileweb_retry_configuration)
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
      "mobileweb" -> survey.mobileweb_retry_configuration
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

  def next_available_date_time(%Survey{} = survey, %DateTime{} = date_time) do
    Schedule.next_available_date_time(survey.schedule, date_time)
  end

  def config_rates() do
    %{
      :valid_respondent_rate => environment_variable_named(:initial_valid_respondent_rate) / 100,
      :eligibility_rate      => environment_variable_named(:initial_eligibility_rate) / 100,
      :response_rate         => environment_variable_named(:initial_response_rate) / 100
    }
  end

  def environment_variable_named(name) do
    case Application.get_env(:ask, Broker)[name] do
      {:system, env_var} ->
        String.to_integer(System.get_env(env_var))
      {:system, env_var, default} ->
        env_value = System.get_env(env_var)
        if env_value do
          String.to_integer(env_value)
        else
          default
        end
      value -> value
    end
  end

  def launched?(survey) do
    survey.state in ["running", "terminated"]
  end

  def adjust_timezone(date_time, %Survey{} = survey) do
    Schedule.adjust_date_to_timezone(survey.schedule, date_time)
  end

  def timezone_offset(%Survey{} = survey) do
    Schedule.timezone_offset(survey.schedule)
  end

  def timezone_offset_in_seconds(%Survey{} = survey) do
    Schedule.timezone_offset_in_seconds(survey.schedule)
  end

  def completed?(survey) do
    survey.state == "terminated" && survey.exit_code == 0
  end

  def cancelled?(survey) do
    survey.state == "terminated" && survey.exit_code == 1
  end

  def has_floip_package?(survey) do
    survey.state == "running" || survey.state == "terminated"
  end

  def cancel_respondents(survey) do
    from(r in Respondent, where: (((r.state == "active") or (r.state == "stalled")) and (r.survey_id == ^survey.id)))
    |> Repo.update_all(set: [state: "cancelled", session: nil, timeout_at: nil])
  end

  def with_links(%Survey{} = survey, level \\ "owner") do
    %{survey | links: links(survey, level)}
  end

  def links(%Survey{} = survey, "owner") do
    links([
      link_name(survey, :results),
      link_name(survey, :incentives),
      link_name(survey, :disposition_history),
      link_name(survey, :interactions)
    ])
  end

  def links(%Survey{} = survey, _) do
    links([
      link_name(survey, :results),
      link_name(survey, :disposition_history)
    ])
  end

  def links(names) do
    ShortLink |> where([l], l.name in ^names) |> Repo.all
  end

  def link_name(%{id: id}, :results), do: "survey/#{id}/results"
  def link_name(%{id: id}, :incentives), do: "survey/#{id}/incentives"
  def link_name(%{id: id}, :disposition_history), do: "survey/#{id}/disposition_history"
  def link_name(%{id: id}, :interactions), do: "survey/#{id}/interactions"

  def running_channels() do
    query = from s in Survey,
      where: s.state == "running",
      join: group in RespondentGroup,
      on: s.id == group.survey_id,
      join: rgc in RespondentGroupChannel,
      on: group.id == rgc.respondent_group_id,
      join: c in Channel,
      on: rgc.channel_id == c.id,
      select: c

    query |> Repo.all
  end

  def survey_channels(s) do
    (s.respondent_groups |> Enum.reduce([], fn group, channels ->
      (group.respondent_group_channels |> Enum.map(&(&1.channel))) ++ channels
    end)) |> Enum.sort_by(&(&1.id))
  end

  def with_down_channels(%Survey{} = survey) do
    channels = survey |> survey_channels
    down_channels = channels
      |> Enum.map(&(&1.id |> ChannelStatusServer.get_channel_status))
      |> Enum.filter(&(&1 != :up && &1 != :unknown))

    %{survey | down_channels: down_channels}
  end
end
