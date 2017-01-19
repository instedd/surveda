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
    field :state, :string, default: "pending" # pending, active, completed, failed, stalled, rejected

    field :completed_at, Timex.Ecto.DateTime # only when state=="pending"
    field :timeout_at, Timex.Ecto.DateTime
    field :session, Ask.Ecto.Type.JSON
    field :mode, Ask.Ecto.Type.JSON
    belongs_to :questionnaire, Ask.Questionnaire
    belongs_to :survey, Ask.Survey
    belongs_to :respondent_group, Ask.RespondentGroup
    belongs_to :quota_bucket, Ask.QuotaBucket
    has_many :responses, Ask.Response

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:phone_number, :state, :session, :quota_bucket_id, :completed_at, :timeout_at, :questionnaire_id, :mode])
    |> validate_required([:phone_number, :state])
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
end
