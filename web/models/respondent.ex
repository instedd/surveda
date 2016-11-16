defmodule Ask.Respondent do
  use Ask.Web, :model

  schema "respondents" do
    field :phone_number, :string
    field :sanitized_phone_number, :string
    field :state, :string, default: "pending" # pending, active, completed, failed
    field :completed_at, Timex.Ecto.DateTime # only when state=="pending"
    field :timeout_at, Timex.Ecto.DateTime
    field :session, Ask.Ecto.Type.JSON
    belongs_to :survey, Ask.Survey
    has_many :responses, Ask.Response

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:phone_number, :state, :session, :completed_at, :timeout_at])
    |> validate_required([:phone_number, :state])
  end

  def sanitize_phone_number(text) do
    ~r/[^\+\d]/ |> Regex.replace(text, "")
  end

  def mask_phone_number(phone_number) do
    Enum.join([replace_numbers_by_hash(String.slice(phone_number, 0..-5)), String.slice(phone_number, -4, 4)], "")
  end

  def replace_numbers_by_hash(string) do
    Regex.replace(~r/[0-9]/, string, "#")
  end
end
