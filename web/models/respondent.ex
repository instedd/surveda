defmodule Ask.Respondent do
  use Ask.Web, :model

  schema "respondents" do
    field :phone_number, :string
    field :sanitized_phone_number, :string
    field :hashed_number, :string

    # Valid states are:
    # * pending: the initial state of a respondent, before communication starts
    # * active: a communication is being held with the respondent
    # * completed: the communication finished succesfully (it reached the end)
    # * failed: communication couldn't be established or was cut, only for IVR
    # * stalled: communication couldn't be established or was cut, only for SMS.
    #            communication might continue if the respondent replies at any time
    # * rejected: communication ended because the respondent fell in a full quota bucket
    field :state, :string, default: "pending"

    # Valid dispositions are:
    # * completed: when the main part of the quiz is complete, even if there are more
    #              steps in the quiz, they aren't of too much importance
    #              (ie: "Thank you for your patience")
    # * partial: when the respondent completed a significant part of the questionnaire,
    #            but there is something more to ask that is also important
    # * ineligible: when the respondent belongs to a group of people that shouldn't be
    #               answering the questionnaire (ie: under 18)
    # * refused: when the respondent when it skips a key question or doesn't want to answer
    #            any more questions and sends the STOP keyword
    # * NULL: if there is no disposition yet (ie: when the survey is still running or about to run,
    #         or if the survey ended without contacting that particular respondent)
    field :disposition, :string

    field :completed_at, Timex.Ecto.DateTime # only when state=="pending"
    field :timeout_at, Timex.Ecto.DateTime
    field :session, Ask.Ecto.Type.JSON
    field :mode, Ask.Ecto.Type.JSON
    field :mobile_web_cookie_code, :string
    field :language, :string
    belongs_to :questionnaire, Ask.Questionnaire
    belongs_to :survey, Ask.Survey
    belongs_to :respondent_group, Ask.RespondentGroup
    belongs_to :quota_bucket, Ask.QuotaBucket
    has_many :responses, Ask.Response
    has_many :survey_log_entries, Ask.SurveyLogEntry

    field :lock_version, :integer, default: 1

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:phone_number, :state, :session, :quota_bucket_id, :completed_at, :timeout_at, :questionnaire_id, :mode, :disposition, :mobile_web_cookie_code, :language])
    |> validate_required([:phone_number, :state])
    |> Ecto.Changeset.optimistic_lock(:lock_version)
  end

  def sanitize_phone_number(text) do
    ~r/[^\d]/ |> Regex.replace(text, "")
  end

  def hash_phone_number(phone_number, salt) do
    String.slice(:crypto.hash(:md5, salt <> phone_number) |> Base.encode16(case: :lower), -12, 12)
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

  def token(respondent_id)do
    String.slice(:crypto.hash(:md5, Application.get_env(:ask, Ask.Endpoint)[:secret_key_base] <> "#{respondent_id}") |> Base.encode16(case: :lower), -12, 12)
  end

  def mobile_web_cookie_name(respondent_id) do
    "mobile_web_code_#{respondent_id}"
  end
end
