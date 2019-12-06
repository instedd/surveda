defmodule Ask.Respondent do
  use Ask.Web, :model
  alias Ask.Ecto.Type.JSON
  alias Ask.{Stats, Repo, Respondent, Survey}

  schema "respondents" do
    field :phone_number, :string
    field :sanitized_phone_number, :string
    field :hashed_number, :string
    field :section_order, JSON

    # Valid states are:
    # * pending: the initial state of a respondent, before communication starts
    # * active: a communication is being held with the respondent
    # * completed: the communication finished succesfully (it reached the end)
    # * failed: communication couldn't be established or was cut, only for IVR
    # * stalled: communication couldn't be established or was cut, only for SMS.
    #            communication might continue if the respondent replies at any time
    # * rejected: communication ended because the respondent fell in a full quota bucket
    # * cancelled: when the survey is stopped and has "terminated" state, all the active
    #              or stalled respondents will be updated with this state.
    field :state, :string, default: "pending"

    # Valid dispositions are:
    # https://cloud.githubusercontent.com/assets/22697/25618659/3126839e-2f1e-11e7-8a3a-7908f8cd1749.png
    # - registered: just created
    # - queued: call queued / SMS queued to be sent
    # - contacted: call answered (or no_answer reply from Verboice) / SMS delivery confirmed
    # - failed: call was never answered / SMS was never sent => the channel was broken or the number doesn't exist
    # - unresponsive: after contacted, when no more retries are available
    # - started: after the first answered question
    # - ineligible: through flag step, only from started, not partial nor completed
    # - rejected: quota completed
    # - breakoff: stopped responding with no more retries, only from started
    # - refused: respondent refused to take the survey, only from started
    # - partial: through flag step, from started
    # - completed: through flag step from started or partial / survey finished with the respondent on started or partial disposition
    field :disposition, :string, default: "registered"

    field :completed_at, Timex.Ecto.DateTime # only when state=="pending"
    field :timeout_at, Timex.Ecto.DateTime
    field :retry_stat_time, :string
    field :session, JSON
    field :mode, JSON
    field :effective_modes, JSON
    field :mobile_web_cookie_code, :string
    field :language, :string
    belongs_to :questionnaire, Ask.Questionnaire
    belongs_to :survey, Ask.Survey
    belongs_to :respondent_group, Ask.RespondentGroup
    belongs_to :quota_bucket, Ask.QuotaBucket
    has_many :responses, Ask.Response
    has_many :survey_log_entries, Ask.SurveyLogEntry
    field :lock_version, :integer, default: 1
    field :stats, Ask.Stats, default: %Ask.Stats{}

    field :experiment_name, :string, virtual: true

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:phone_number, :sanitized_phone_number, :state, :session, :quota_bucket_id, :completed_at, :timeout_at, :questionnaire_id, :mode, :disposition, :mobile_web_cookie_code, :language, :effective_modes, :stats, :section_order, :retry_stat_time])
    |> validate_required([:phone_number, :state])
    |> Ecto.Changeset.optimistic_lock(:lock_version)
  end

  def sanitize_phone_number(text) do
    ~r/[^\d]/ |> Regex.replace(text, "")
  end

  def hash_phone_number(phone_number, salt) do
    "r" <> (String.slice(:crypto.hash(:md5, salt <> phone_number) |> Base.encode16(case: :lower), -12, 12))
  end

  def mask_phone_number(phone_number) do
    Enum.join([replace_numbers_by_hash(String.slice(phone_number, 0..-5)), String.slice(phone_number, -4, 4)], "")
  end

  def replace_numbers_by_hash(string) do
    Regex.replace(~r/[0-9]/, string, "#")
  end

  def show_disposition(disposition) do
    (disposition || "") |> String.capitalize
  end

  def show_section_order(%{section_order: nil}, _), do: ""

  def show_section_order(%{section_order: section_order, questionnaire_id: questionnaire_id}, questionnaires) do
    questionnaire = questionnaires |> Enum.find(fn q -> q.id == questionnaire_id end)
    Enum.map(section_order, fn i -> questionnaire.steps |> Enum.at(i) |> show_section_title(i) end) |> Enum.join(", ")
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

  def token(respondent_id)do
    String.slice(:crypto.hash(:md5, Application.get_env(:ask, Ask.Endpoint)[:secret_key_base] <> "#{respondent_id}") |> Base.encode16(case: :lower), -12, 12)
  end

  def mobile_web_cookie_name(respondent_id) do
    "mobile_web_code_#{respondent_id}"
  end

  def add_mode_attempt!(respondent, mode), do: respondent |> changeset(%{stats: Stats.add_attempt(respondent.stats, mode)}) |> Repo.update!

  @doc """
  Computes the date-time on which the respondent should be retried or stalled given the timeout and time-window availability
  """
  def next_actual_timeout(%Respondent{} = respondent, timeout, now) do
    timeout_at = next_timeout_lowerbound(timeout, now)
    (respondent |> Repo.preload(:survey)).survey
    |> Survey.next_available_date_time(timeout_at)
  end

  def next_timeout_lowerbound(timeout, now), do:
    Timex.shift(now, minutes: timeout)

end
