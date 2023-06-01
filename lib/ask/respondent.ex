defmodule Ask.Respondent do
  use Ask.Model
  alias Ask.Ecto.Type.JSON
  alias Ask.{Stats, Repo, Respondent, Survey, Questionnaire}
  alias Ask.Runtime.Reply

  schema "respondents" do
    # phone_number as-it-is in the respondents_list
    field :phone_number, :string

    # phone_number with the channel's patterns applied `channel.apply_patterns(canonical_phone_number)`
    field :sanitized_phone_number, :string
    # phone_number with the basic prunes/validations applied
    field :canonical_phone_number, :string
    field :hashed_number, :string
    field :section_order, JSON

    field :state, Ecto.Enum,
      values: [
        # the initial state of a respondent, before communication starts
        :pending,
        # a communication is being held with the respondent
        :active,
        # the communication finished succesfully (it reached the end)
        :completed,
        # communication couldn't be established or was cut
        :failed,
        # communication ended because the respondent fell in a full quota bucket
        :rejected,
        # when the survey is stopped and has :terminated state, all the active respondents will be updated with this state.
        :cancelled
      ],
      default: :pending

    # Disposition flow:
    #
    #     ┌───────────────┐       ┌───────────────┐     ┌──────────────┐
    #     │   Registered  ├───────►    Queued     ├─────►    Failed    │
    #     └───────────────┘       └───────┬───────┘     └──────────────┘
    #                                     │
    #                             ┌───────▼───────┐     ┌──────────────┐
    #                           ┌─│   Contacted   ├─────► Unresponsive │
    #                           │ └───────┬───────┘     └──────────────┘
    #     ┌─────────────────┐   │         │
    #     │     Refused     ◄───┤         │
    #     └─────────────────┘   │         │
    #                           │ ┌───────▼───────┐     ┌──────────────┐
    #                           └─┤    Started    │─────►   Breakoff   │
    #                             └───────┬─────┬─┘     └──────────────┘
    #                                     │     │
    #     ┌─────────────────┐             │     │       ┌──────────────┐
    #     │ Interim partial ◄─────────────┤     │     ┌─►   Rejected   │
    #     └────────┬────────┘             │     │     │ └──────────────┘
    #              │                      │     └─────┤
    #              ├──────────────────┐   │           │ ┌──────────────┐
    #              │                  │   │           └─►  Ineligible  │
    #              │                  │   │             └──────────────┘
    #     ┌────────▼────────┐     ┌───▼───▼───────┐
    #     │     Partial     │     │   Completed   │
    #     └─────────────────┘     └───────────────┘
    #
    field :disposition, Ecto.Enum,
      values: [
        # Uncontacted:
        # initial state
        :registered,
        # call/SMS queued for call/delivery
        :queued,
        # call was never answered / SMS was never sent => the channel was broken or the number doesn't exist
        :failed,

        # Contacted:
        # call answered (or no_answer reply from Verboice) / SMS delivery confirmed
        :contacted,
        # exhausted retries after initial contact
        :unresponsive,

        # Responsive:
        # respondent refused to take the survey (e.g. sent STOP MO)
        :refused,
        # answered at least one question
        :started,
        # reached 'ineligible' flag step
        :ineligible,
        # reached full quota
        :rejected,
        # stopped responding (exhausted retries) or sent STOP MO
        :breakoff,
        # reached 'partial' flag step
        :"interim partial",
        # stopped responding after reaching 'partial' flag step
        :partial,
        # reached 'completed' flag step => DONE
        :completed
      ],
      default: :registered

    # only when state==:pending
    field :completed_at, :utc_datetime
    field :timeout_at, :utc_datetime
    field :session, JSON
    # In Respondent model, "mode" field name should change in the future.
    # This word is used a lot in Surveda, describing related (but different) things.
    # Because here it describes a mode sequence, it could be named "mode_sequence".
    # Each mode sequence is the combination of two differente modes: primary and fallback modes.
    # It may seem it represents a single mode when there is no fallback mode. But it doesn't.
    # This is why it's always represented as an array, having or not having a fallback mode.
    # Examples:
    # * ["sms"] -> SMS as primary mode, no fallback mode
    # * ["ivr", "mobileweb"] -> IVR as primary mode, Mobileweb as fallback mode
    # * ["mobileweb", "ivr"] -> Mobileweb as primary mode, IVR as fallback mode
    field :mode, JSON
    field :effective_modes, JSON
    field :language, :string
    belongs_to :questionnaire, Questionnaire
    belongs_to :survey, Ask.Survey
    belongs_to :respondent_group, Ask.RespondentGroup
    belongs_to :quota_bucket, Ask.QuotaBucket
    belongs_to :retry_stat, Ask.RetryStat
    has_many :responses, Ask.Response
    has_many :survey_log_entries, Ask.SurveyLogEntry
    field :lock_version, :integer, default: 1
    field :stats, Ask.Stats, default: %Ask.Stats{}
    field :experiment_name, :string, virtual: true
    field :user_stopped, :boolean, default: false

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :phone_number,
      :sanitized_phone_number,
      :canonical_phone_number,
      :state,
      :session,
      :quota_bucket_id,
      :completed_at,
      :timeout_at,
      :questionnaire_id,
      :mode,
      :disposition,
      :language,
      :effective_modes,
      :stats,
      :section_order,
      :retry_stat_id,
      :user_stopped
    ])
    |> validate_required([:phone_number, :state, :user_stopped])
    |> validate_inclusion(:disposition, Ecto.Enum.values(Ask.Respondent, :disposition))
    |> validate_inclusion(:state, Ecto.Enum.values(Ask.Respondent, :state))
    |> Ecto.Changeset.optimistic_lock(:lock_version)
  end

  def canonicalize_phone_number(text) do
    ~r/[^\d]/ |> Regex.replace(text, "")
  end

  def hash_phone_number(phone_number, salt) do
    "r" <>
      String.slice(
        :crypto.hash(:md5, salt <> phone_number) |> Base.encode16(case: :lower),
        -12,
        12
      )
  end

  def mask_respondent_entry(entry) do
    if is_respondent_id?(entry) do
      entry
    else
      mask_phone_number(entry)
    end
  end

  def mask_phone_number(phone_number) do
    Enum.join(
      [
        replace_numbers_by_hash(String.slice(phone_number, 0..-5)),
        String.slice(phone_number, -4, 4)
      ],
      ""
    )
  end

  def is_phone_number?(entry), do: Regex.match?(~r/^([0-9]|\(|\)|\+|\-| )+$/, entry)
  def is_respondent_id?(entry), do: Regex.match?(~r/^r([a-zA-Z0-9]){12}$/, entry)

  def replace_numbers_by_hash(string) do
    Regex.replace(~r/[0-9]/, string, "#")
  end

  def show_disposition(disposition) do
    (disposition || "") |> to_string() |> String.capitalize()
  end

  def show_section_order(%{section_order: nil}, _), do: ""

  def show_section_order(
        %{section_order: section_order, questionnaire_id: questionnaire_id},
        questionnaires
      ) do
    questionnaire = questionnaires |> Enum.find(fn q -> q.id == questionnaire_id end)

    Enum.map(section_order, fn i -> questionnaire.steps |> Enum.at(i) |> show_section_title(i) end)
    |> Enum.join(", ")
  end

  defp show_section_title(%{"title" => nil}, index) do
    "Untitled #{index + 1}"
  end

  defp show_section_title(%{"title" => ""}, index) do
    "Untitled #{index + 1}"
  end

  defp show_section_title(%{"title" => title}, _) do
    title
  end

  def token(respondent_id) do
    String.slice(
      :crypto.hash(
        :md5,
        Application.get_env(:ask, AskWeb.Endpoint)[:secret_key_base] <> "#{respondent_id}"
      )
      |> Base.encode16(case: :lower),
      -12,
      12
    )
  end

  def completed_dispositions(count_partial_results \\ false)

  def completed_dispositions(false), do: [:completed]

  def completed_dispositions(true), do: completed_dispositions() ++ [:partial, :"interim partial"]

  def completed_disposition?(disposition, count_partial_results \\ false),
    do:
      Respondent.completed_dispositions(count_partial_results)
      |> Enum.member?(disposition)

  def enters_in_completed_disposition?(
        old_disposition,
        new_disposition,
        count_partial_results \\ false
      ),
      do:
        !completed_disposition?(old_disposition, count_partial_results) &&
          completed_disposition?(new_disposition, count_partial_results)

  @doc """
    Did the respondent incremented their quota?
  """
  def incremented_their_quota?(quota_bucket_id, disposition, count_partial_results),
    do:
      quota_bucket_id != nil &&
        completed_disposition?(disposition, count_partial_results)

  def final_dispositions(),
    do: [
      :failed,
      :unresponsive,
      :ineligible,
      :rejected,
      :breakoff,
      :refused,
      :partial,
      :completed
    ]

  def non_final_dispositions(),
    do: [
      :registered,
      :queued,
      :contacted,
      :started,
      :"interim partial"
    ]

  # Interim partial was created to distinguish between the respondents that reached partial but
  # still can reach a complete and those who cannot. In the context of the current cockpit, it
  # doesn't make sense to maintain this distinction when Count partial as complete is selected.

  @doc """
  The dispositions listed here are considered final for metrics.
  """
  def metrics_final_dispositions(_count_partial_results \\ false)

  def metrics_final_dispositions(false), do: final_dispositions()

  @doc """
  Interim partial isn't a final disposition but it's considered final for metrics
  """
  def metrics_final_dispositions(true), do: final_dispositions() ++ [:"interim partial"]

  @doc """
  The dispositions listed here are considered non final for metrics.
  """
  def metrics_non_final_dispositions(count_partial_results \\ false)

  def metrics_non_final_dispositions(false), do: non_final_dispositions()

  @doc """
  Interim partial is a non final disposition but it's considered final for metrics
  """
  def metrics_non_final_dispositions(true),
    do: List.delete(non_final_dispositions(), :"interim partial")

  def add_mode_attempt!(respondent, mode),
    do:
      respondent
      |> changeset(%{stats: Stats.add_attempt(respondent.stats, mode)})
      |> Repo.update!()

  def call_attempted(%{stats: %{pending_call: false}} = respondent), do: respondent

  def call_attempted(%{stats: stats} = respondent),
    do: respondent |> changeset(%{stats: Stats.with_last_call_attempted(stats)}) |> Repo.update!()

  @doc """
  Computes the date-time on which the respondent should be retried given the timeout and time-window availability
  """
  def next_actual_timeout(%Respondent{} = respondent, timeout, now, persist \\ true) do
    timeout_at = next_timeout_lowerbound(timeout, now)

    respondent
    |> survey(persist)
    |> Survey.next_available_date_time(timeout_at)
  end

  defp survey(respondent, persist) do
    if(persist) do
      (respondent |> Repo.preload(:survey)).survey
    else
      respondent.survey
    end
  end

  @doc """
  Computes the date-time on which the respondent would be retried , ignoring their survey's inactivity windows (ie, if it Schedule was to always run)
  """
  def next_timeout_lowerbound(timeout, now), do: Timex.shift(now, minutes: timeout)

  @doc """
  This function uses Mutex. Its locks aren't reentrant
  Avoid nesting locks to prevent deadlocks
  """
  def with_lock(respondent_id, operation, respondent_modifier \\ fn x -> x end) do
    # `respondent_id` can be either an Integer or its String representation depending on
    # the caller. Since we need a unified key to access the Mutex, we here convert it to
    # a string - even if it's in a non-politically-correct way
    mutex_key = "#{respondent_id}"

    Mutex.under(Ask.Mutex, mutex_key, fn ->
      respondent =
        Respondent
        |> Repo.get(respondent_id)
        |> respondent_modifier.()

      operation.(respondent)
    end)
  end

  def update(respondent, changes, persist) do
    if(persist) do
      respondent
      |> Respondent.changeset(changes)
      |> Repo.update!()
    else
      Map.merge(respondent, changes)
    end
  end

  def stored_responses(respondent, persist \\ true),
    do:
      if(persist,
        do: from(r in Ask.Response, where: r.respondent_id == ^respondent.id) |> Repo.all(),
        else: respondent.responses
      )

  def partial_relevant_answered_count(respondent, persist \\ true)

  def partial_relevant_answered_count(
        %{questionnaire: nil} = _respondent,
        _persist
      ),
      do: 0

  def partial_relevant_answered_count(
        %{questionnaire: questionnaire} = respondent,
        persist
      ) do
    partial_relevant_enabled =
      Questionnaire.partial_relevant_enabled?(questionnaire.partial_relevant_config)

    if partial_relevant_enabled do
      Respondent.stored_responses(respondent, persist)
      |> Enum.count(fn response -> relevant_response?(questionnaire, response) end)
    else
      0
    end
  end

  defp relevant_response?(questionnaire, response) do
    ignored_values = Questionnaire.ignored_values_from_relevant_steps(questionnaire)
    relevant_response?(questionnaire, ignored_values, response)
  end

  def relevant_response?(questionnaire, ignored_values, response) do
    quiz_step =
      questionnaire
      |> Questionnaire.all_steps()
      |> Enum.find(fn step -> step["store"] == response.field_name end)

    not_ignored = fn value -> String.upcase(value) not in ignored_values end
    quiz_step["relevant"] && not_ignored.(response.value)
  end


  @doc """
  Updates the respondent stats

  ## Parameters

    - respondent: the respondent being updated
    - reply: the reply to extract the stats
    - received_sms?: if true, both stats (sent and received) are updated
  """
  def update_stats(respondent_id, reply \\ %Reply{}, received_sms? \\ false) do
    respondent = Repo.get(Respondent, respondent_id)
    stats = respondent.stats

    stats =
      stats
      |> Stats.add_sent_sms(Enum.count(Reply.prompts(reply)))

    stats = if received_sms?, do: Stats.add_received_sms(stats), else: stats

    respondent
    |> Respondent.changeset(%{stats: stats})
    |> Repo.update!()
  end

end
