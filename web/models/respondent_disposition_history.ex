defmodule Ask.RespondentDispositionHistory do
  use Ask.Web, :model
  alias Ask.{RespondentDispositionHistory, Repo}

  schema "respondent_disposition_history" do
    field :disposition, :string
    field :mode, :string
    belongs_to :respondent, Ask.Respondent
    belongs_to :survey, Ask.Survey
    field :respondent_hashed_number, :string

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:disposition, :mode])
    |> validate_required([:disposition])
  end

  def create(respondent, old_disposition, mode) do
    if respondent.disposition && respondent.disposition != old_disposition do
      %RespondentDispositionHistory{
        respondent: respondent,
        disposition: respondent.disposition |> to_string(),
        mode: mode,
        survey_id: respondent.survey_id,
        respondent_hashed_number: respondent.hashed_number
      }
      |> Repo.insert!
    end
    respondent
  end
end
