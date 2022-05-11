defmodule Ask.Survey do
  use Ask.Model

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
    Folder,
    RespondentStats,
    ConfigHelper,
    SystemTime,
    PanelSurvey
  }

  alias Ask.Runtime.ChannelStatusServer
  alias Ask.Ecto.Type.JSON
  alias Ecto.Multi

  @max_int 2_147_483_647
  @default_fallback_delay 120

  schema "surveys" do
    field :name, :string
    field :description, :string
    # In Survey model, "mode" field name should change in the future.
    # This word is used a lot in Surveda, describing related (but different) things.
    # Because here it describes comparisions of different mode sequences, it could be named "mode_sequence_comparisions".
    # Each mode sequence is the combination of two differente modes: primary and fallback modes.
    # It may seem it represents a single mode when there is neither a comparision nor a fallback mode.
    # But it doesn't. This is why it's always represented as a two dimensional array,
    # having or not having comparisions and fallback modes.
    # Examples:
    # * [["sms"]] -> SMS as primary mode, no fallback mode, no comparision
    # * [["ivr", "mobileweb]] -> IVR as primary mode, Mobileweb as fallback mode, no comparision
    # * [["mobileweb", "ivr"], ["sms"]] -> 2 comparisions:
    #   * 1st mode sequence: Mobileweb as primary mode, IVR as fallback mode
    #   * 2nd mode sequence: SMS as primary mode, no fallback mode
    field :mode, JSON
    # not_ready, ready, pending, running, terminated, cancelling
    field :state, Ecto.Enum,
      values: [
        :not_ready,
        :ready,
        :pending,
        :running,
        :terminated,
        :cancelling
      ],
      default: :not_ready

    field :locked, :boolean, default: false
    field :exit_code, :integer
    field :exit_message, :string
    # Cutoff options:
    # cutoff == null -> (valid and default value) the user selected "No cutoff" radio button or didn't select any cutoff option
    # cutoff == 0 -> (invalid value) the user selected "Number of completes" radio button and filled it with no value
    # cutoff > 0 -> (valid value) the user selected "Number of completes" radio button and filled it with a positive number
    field :cutoff, :integer
    field :count_partial_results, :boolean, default: false
    field :schedule, Schedule, default: Schedule.default()
    # The moment when the survey changes to %{state: :running} and the moment when the survey
    # becomes actually active may differ because of its schedule configuration.
    # started_at: the moment when the survey change to %{state: :running}.
    field :started_at, :utc_datetime

    # first_window_started_at: the moment when the survey becomes actually active for the first time.
    field :first_window_started_at, :utc_datetime
    field :ended_at, :utc_datetime
    field :last_window_ends_at, :utc_datetime
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
    # The option of downloading incentive files is disabled for a survey after creating 1 or more
    # respondents using a file with hashed_numbers (instead of phone_numbers)
    field :incentives_enabled, :boolean, default: true

    # When this flag is ON, the survey is considered the first wave of a panel survey. It's listed
    # on the UI as a panel survey and, when it's launched, it generates a panel survey. To see
    # more details of this process, please take a look at the following function:
    #  - Ask.Runtime.PanelSurveycreate_panel_survey_from_survey/1
    # When this flag is OFF, the survey is considered a regular survey. It won't ever generate any
    # panel survey.
    # This flag is the result of the iterative approach used to develop panel surveys.
    # In previous iterations, the survey edition page had a switch and it generated (or not) a
    # panel survey depending on that setting. Currently, the flag is set only once, when a regular
    # survey or the first wave of a panel survey is created, and it doesn't ever change.
    # Considering the current state of panel surveys development, this flag should dissapear. For
    # doing that, the panel survey creation process must be moved to be part of its first wave
    # creation process. The only reason why that wasn't done yet is the refactor would take more
    # time that we have to do it.
    field :generates_panel_survey, :boolean, default: false

    has_many :respondent_groups, RespondentGroup
    has_many :respondents, Respondent
    has_many :quota_buckets, QuotaBucket, on_replace: :delete

    # Before the survey is launched, the user selects one or more questionnaires
    # Until the survey is launched, it's directly related to these questionnaires
    # These original questionnaires are totally updatable in any moment
    # From the moment the survey is launched, these questionnaires are replaced by snapshots
    # Besides they remain related to its original by `snapshot_of`, they aren't updatable at all
    many_to_many :questionnaires, Questionnaire,
      join_through: SurveyQuestionnaire,
      on_replace: :delete

    has_many :floip_endpoints, FloipEndpoint

    belongs_to :project, Project
    belongs_to :folder, Folder
    belongs_to :panel_survey, PanelSurvey

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :name,
      :description,
      :project_id,
      :folder_id,
      :mode,
      :state,
      :locked,
      :exit_code,
      :exit_message,
      :cutoff,
      :schedule,
      :sms_retry_configuration,
      :ivr_retry_configuration,
      :mobileweb_retry_configuration,
      :fallback_delay,
      :started_at,
      :quotas,
      :quota_vars,
      :comparisons,
      :count_partial_results,
      :simulation,
      :ended_at,
      :incentives_enabled,
      :first_window_started_at,
      :last_window_ends_at,
      :panel_survey_id,
      :generates_panel_survey
    ])
    |> set_floip_package_id
    |> validate_required([:project_id, :state, :schedule])
    |> foreign_key_constraint(:project_id)
    |> foreign_key_constraint(:panel_survey_id)
    |> validate_from_less_than_to
    |> validate_number(:cutoff, greater_than_or_equal_to: 0, less_than: @max_int)
    |> translate_quotas
    |> set_ended_at_in_terminated_survey
  end

  defp set_ended_at_in_terminated_survey(changeset) do
    if get_field(changeset, :state) == :terminated do
      change(changeset, ended_at: SystemTime.time().now |> DateTime.truncate(:second))
    else
      changeset
    end
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
      change(changeset, floip_package_id: Ecto.UUID.generate())
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
      state == :not_ready && ready ->
        change(changeset, state: :ready)

      state == :ready && !ready ->
        change(changeset, state: :not_ready)

      true ->
        changeset
    end
  end

  def editable?(%{state: :running}), do: false
  def editable?(%{state: :terminated}), do: false
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
    length(questionnaires) > 0 && Enum.all?(questionnaires, & &1.valid)
  end

  defp schedule_ready?(changeset) do
    get_field(changeset, :schedule)
    |> Schedule.any_day_selected?()
  end

  defp mode_ready?(changeset) do
    mode = get_field(changeset, :mode)
    mode && length(mode) > 0
  end

  defp mode_and_questionnaires_ready?(changeset) do
    mode = get_field(changeset, :mode)
    questionnaires = get_field(changeset, :questionnaires)

    # Check that all survey modes are present in the associated questionnaires
    mode
    |> Enum.all?(fn modes ->
      modes
      |> Enum.all?(fn mode ->
        questionnaires
        |> Enum.all?(fn q ->
          q.modes |> Enum.member?(mode)
        end)
      end)
    end)
  end

  def comparisons_ready?(changeset) do
    comparisons = get_field(changeset, :comparisons)

    if comparisons && length(comparisons) > 0 do
      sum =
        comparisons
        |> Enum.map(&Map.get(&1, "ratio", 0))
        |> Enum.sum()

      sum == 100
    else
      true
    end
  end

  def cutoff_ready?(changeset) do
    quota_buckets = get_field(changeset, :quota_buckets)
    cutoff = get_field(changeset, :cutoff)

    if quota_buckets && length(quota_buckets) > 0 do
      sum =
        quota_buckets
        |> Enum.map(&Map.get(&1, :quota, 0))
        |> Enum.filter(& &1)
        |> Enum.sum()

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
    quota_count =
      quota_buckets
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

    Enum.all?(mode, fn modes ->
      Enum.all?(modes, fn m -> Enum.any?(channels, fn c -> m == c.mode end) end)
    end)
  end

  defp retry_attempts_ready?(changeset) do
    sms_retry_configuration = get_field(changeset, :sms_retry_configuration)
    ivr_retry_configuration = get_field(changeset, :ivr_retry_configuration)
    mobileweb_retry_configuration = get_field(changeset, :mobileweb_retry_configuration)

    valid_retry_configurations?(sms_retry_configuration) &&
      valid_retry_configurations?(ivr_retry_configuration) &&
      valid_retry_configurations?(mobileweb_retry_configuration)
  end

  defp fallback_delay_ready?(changeset) do
    fallback_delay = get_field(changeset, :fallback_delay)
    valid_retry_configuration?(fallback_delay)
  end

  defp valid_retry_configurations?(retry_configurations) do
    !retry_configurations ||
      Enum.all?(String.split(retry_configurations), fn s -> valid_retry_configuration?(s) end)
  end

  defp valid_retry_configuration?(retry_configuration) do
    !retry_configuration || Regex.match?(~r/^\d+[mdh]$/, retry_configuration)
  end

  def retries_configuration(survey, mode) do
    retries =
      case mode do
        "sms" -> survey.sms_retry_configuration
        "ivr" -> survey.ivr_retry_configuration
        "mobileweb" -> survey.mobileweb_retry_configuration
        _ -> nil
      end

    parse_retries(retries)
  end

  def default_fallback_delay do
    @default_fallback_delay
  end

  def fallback_delay(survey) do
    if survey.fallback_delay do
      parse_retry_item(survey.fallback_delay |> String.trim(), nil)
    else
      @default_fallback_delay
    end
  end

  defp parse_retries(nil), do: []

  defp parse_retries(retries) do
    retries
    |> String.split()
    |> Enum.map(&parse_retry_item(&1))
    |> Enum.reject(fn x -> x == 0 end)
  end

  defp parse_retry_item(value, on_error \\ 0) do
    case Integer.parse(value) do
      :error ->
        on_error

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
      :eligibility_rate => environment_variable_named(:initial_eligibility_rate) / 100,
      :response_rate => environment_variable_named(:initial_response_rate) / 100
    }
  end

  def environment_variable_named(name),
    do: ConfigHelper.get_config(Ask.Runtime.Broker, name, &String.to_integer/1)

  def launched?(survey) do
    survey.state in [:running, :terminated]
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
    survey.state == :terminated && survey.exit_code == 0
  end

  def cancelled?(survey) do
    survey.state == :terminated && survey.exit_code == 1
  end

  def has_floip_package?(survey) do
    survey.state == :running || survey.state == :terminated
  end

  def cancel_respondents(survey) do
    from(r in Respondent, where: r.state == :active and r.survey_id == ^survey.id)
    |> Repo.update_all(set: [state: :cancelled, session: nil, timeout_at: nil])
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
    ShortLink |> where([l], l.name in ^names) |> Repo.all()
  end

  def link_name(%{id: id}, :results), do: "survey/#{id}/results"
  def link_name(%{id: id}, :incentives), do: "survey/#{id}/incentives"
  def link_name(%{id: id}, :disposition_history), do: "survey/#{id}/disposition_history"
  def link_name(%{id: id}, :interactions), do: "survey/#{id}/interactions"

  def running_channels() do
    query =
      from s in Survey,
        where: s.state == :running,
        join: group in RespondentGroup,
        on: s.id == group.survey_id,
        join: rgc in RespondentGroupChannel,
        on: group.id == rgc.respondent_group_id,
        join: c in Channel,
        on: rgc.channel_id == c.id,
        select: c

    query |> Repo.all()
  end

  def survey_channels(s) do
    s.respondent_groups
    |> Enum.reduce([], fn group, channels ->
      (group.respondent_group_channels |> Enum.map(& &1.channel)) ++ channels
    end)
    |> Enum.sort_by(& &1.id)
  end

  def with_down_channels(%Survey{} = survey) do
    channels = survey |> survey_channels

    down_channels =
      channels
      |> Enum.map(&(&1.id |> ChannelStatusServer.get_channel_status()))
      |> Enum.filter(&(&1 != :up && &1 != :unknown))

    %{survey | down_channels: down_channels}
  end

  def stats(survey) do
    respondents_by_disposition = survey |> RespondentStats.respondents_by_disposition()

    respondents_total =
      Enum.map(respondents_by_disposition, fn {_, v} -> v end)
      |> Enum.reduce(0, fn q, acc -> q + acc end)

    respondents_target =
      survey
      |> completed_respondents_needed_by
      |> respondents_target(respondents_total)

    completion_rate = get_completion_rate(survey, respondents_by_disposition, respondents_target)
    current_success_rate = get_success_rate(survey, respondents_by_disposition)
    initial_success_rate = initial_success_rate()
    completed_respondents = get_completed_respondents(survey, respondents_by_disposition)
    additional_completes = respondents_target - completed_respondents

    estimated_success_rate =
      estimated_success_rate(initial_success_rate, current_success_rate, completion_rate)

    exhausted = exhausted_respondents(respondents_by_disposition, survey.count_partial_results)

    available =
      not_exhausted_respondents(respondents_by_disposition, survey.count_partial_results)

    needed_to_complete = Kernel.trunc(Float.round(additional_completes / estimated_success_rate))

    additional_respondents =
      if needed_to_complete - available > 0, do: needed_to_complete - available, else: 0

    success_rate = if exhausted > 0, do: Float.round(current_success_rate, 3), else: 0.0

    %{
      success_rate_data: %{
        success_rate: success_rate,
        completion_rate: Float.round(completion_rate, 3),
        initial_success_rate: Float.round(initial_success_rate, 3),
        estimated_success_rate: Float.round(estimated_success_rate, 3)
      },
      queue_size_data: %{
        exhausted: exhausted,
        available: available,
        additional_completes: additional_completes,
        needed_to_complete: needed_to_complete,
        additional_respondents: additional_respondents
      }
    }
  end

  def get_completion_rate(survey, respondents_by_disposition, respondents_target) do
    completed_dispositions = Respondent.completed_dispositions(survey.count_partial_results)

    completed_respondents =
      successful_respondents(survey, respondents_by_disposition, completed_dispositions)

    completion_rate(completed_respondents, respondents_target)
  end

  def completion_rate(_, nil), do: 0.0
  def completion_rate(_, 0), do: 0.0
  def completion_rate(completed, respondents_target), do: completed / respondents_target

  def get_success_rate(survey, respondents_by_disposition) do
    completed_respondents = get_completed_respondents(survey, respondents_by_disposition)

    exhausted_respondents =
      exhausted_respondents(respondents_by_disposition, survey.count_partial_results)

    success_rate(completed_respondents, exhausted_respondents)
  end

  def get_completed_respondents(survey, respondents_by_disposition) do
    completed_dispositions = Respondent.completed_dispositions(survey.count_partial_results)
    sum_respondents_by_disposition_filter(respondents_by_disposition, completed_dispositions)
  end

  def success_rate(_, 0), do: 1.0

  def success_rate(successful_respondents, exhausted_respondents) do
    successful_respondents / exhausted_respondents
  end

  defp respondents_target(:all, respondents_total), do: respondents_total
  defp respondents_target(completed_respondents_needed, _), do: completed_respondents_needed

  def initial_success_rate() do
    %{
      :valid_respondent_rate => initial_valid_respondent_rate,
      :eligibility_rate => initial_eligibility_rate,
      :response_rate => initial_response_rate
    } = config_rates()

    initial_valid_respondent_rate * initial_eligibility_rate * initial_response_rate
  end

  def estimated_success_rate(initial_success_rate, current_success_rate, completion_rate),
    do: (1 - completion_rate) * initial_success_rate + completion_rate * current_success_rate

  def completed_respondents_needed_by(survey) do
    survey_id = survey.id

    quota_target =
      Repo.one(
        from q in QuotaBucket,
          where: q.survey_id == ^survey_id,
          select: sum(q.quota)
      )

    cutoff_target = survey.cutoff
    targets_compacted = [quota_target, cutoff_target] |> Enum.reject(&is_nil/1)

    if targets_compacted |> Enum.empty?() do
      :all
    else
      res =
        targets_compacted
        |> Enum.max()
        |> Decimal.new()
        |> Decimal.to_integer()

      res
    end
  end

  def successful_respondents(%Survey{} = survey, respondents_by_disposition, disposition_filter) do
    quota_completed =
      Repo.one(
        from q in (survey |> assoc(:quota_buckets)),
          select: fragment("sum(least(count, quota))")
      )

    successful_respondents(quota_completed, respondents_by_disposition, disposition_filter)
  end

  def successful_respondents(nil, respondents_by_disposition, disposition_filter) do
    respondents_by_disposition |> sum_respondents_by_disposition_filter(disposition_filter)
  end

  def successful_respondents(quota_completed, _, _), do: quota_completed |> Decimal.to_integer()

  def belongs_to_panel_survey?(%{panel_survey_id: panel_survey_id}), do: !!panel_survey_id

  defp exhausted_respondents(respondents_by_disposition, count_partial_results) do
    disposition_filter = Respondent.metrics_final_dispositions(count_partial_results)
    sum_respondents_by_disposition_filter(respondents_by_disposition, disposition_filter)
  end

  defp not_exhausted_respondents(respondents_by_disposition, count_partial_results) do
    disposition_filter = Respondent.metrics_non_final_dispositions(count_partial_results)
    sum_respondents_by_disposition_filter(respondents_by_disposition, disposition_filter)
  end

  def sum_respondents_by_disposition_filter(respondents_by_disposition, disposition_filter) do
    respondents_by_disposition
    |> Enum.reduce(0, fn {disposition, count}, acc ->
      if disposition in disposition_filter, do: acc + count, else: acc
    end)
  end

  def completed_state_respondents(survey, respondents_by_state) do
    quota_completed =
      Repo.one(
        from q in (survey |> assoc(:quota_buckets)),
          select: fragment("sum(least(count, quota))")
      )

    case quota_completed do
      nil -> respondents_by_state[:completed]
      value -> value |> Decimal.to_integer()
    end
  end

  def partial_relevant_enabled?(survey, persist \\ false) do
    partial_relevant_configs = partial_relevant_configs(survey, persist)

    Enum.any?(partial_relevant_configs, fn config ->
      Questionnaire.partial_relevant_enabled?(config)
    end)
  end

  def terminated?(survey), do: survey.state == :terminated

  def succeeded?(survey), do: terminated?(survey) and survey.exit_code == 0

  defp partial_relevant_configs(survey, true = _persist),
    do:
      from(sq in SurveyQuestionnaire,
        join: q in Questionnaire,
        on: q.id == sq.questionnaire_id,
        where: sq.survey_id == ^survey.id,
        select: q.partial_relevant_config
      )
      |> Repo.all()

  defp partial_relevant_configs(survey, _persist),
    do:
      survey.questionnaires
      |> Enum.map(fn q -> q.partial_relevant_config end)

  def update_questionnaires(changeset, questionnaire_ids) do
    questionnaires_changeset =
      Enum.map(questionnaire_ids, fn questionnaire_id ->
        Repo.get!(Questionnaire, questionnaire_id) |> change
      end)

    changeset
    |> put_assoc(:questionnaires, questionnaires_changeset)
  end

  def update_respondent_groups(changeset, respondent_group_ids) do
    respondent_groups_changeset =
      Enum.map(respondent_group_ids, fn respondent_group_id ->
        Repo.get!(RespondentGroup, respondent_group_id) |> change
      end)

    changeset
    |> put_assoc(:respondent_groups, respondent_groups_changeset)
  end

  def delete_multi(survey) do
    Multi.delete(Multi.new(), :survey, survey)
  end

  def expired?(survey, date_time \\ SystemTime.time().now)

  def expired?(%{last_window_ends_at: nil} = _survey, _date_time), do: false

  def expired?(
        %{last_window_ends_at: last_window_ends_at, schedule: %{timezone: timezone}} = _survey,
        date_time
      ) do
    # Just in case, the expiration is delayed 5 minutes.
    expiration_date_time = Timex.shift(last_window_ends_at, minutes: 5)

    date_time
    |> Timex.to_datetime(timezone)
    # -1 -- the first date comes before the second one
    # 0 -- both arguments represent the same date when coalesced to the same timezone.
    # 1 -- the first date comes after the second one
    |> Timex.compare(expiration_date_time) > -1
  end

  # Running surveys aren't deletable
  def deletable?(%{state: :running} = _survey), do: false
  # Only wave of a panel survey isn't deletable (because a panel survey cannot be empty)
  def deletable?(survey), do: not only_wave_of_panel_survey?(survey)

  # Regular survey can always change its folder
  def movable?(%{panel_survey_id: nil} = _survey), do: true
  # Panel survey waves can't change its folder by its own, although the PanelSurvey
  # they belong to, can be moved to a folder
  def movable?(_survey), do: false

  defp only_wave_of_panel_survey?(%{panel_survey_id: nil} = _survey), do: false

  defp only_wave_of_panel_survey?(survey) do
    survey = Repo.preload(survey, panel_survey: :waves)
    Enum.count(survey.panel_survey.waves) == 1
  end
end
