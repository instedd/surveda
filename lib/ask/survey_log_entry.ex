defmodule Ask.SurveyLogEntry do
  use Ask.Model

  schema "survey_log_entries" do
    belongs_to :survey, Ask.Survey
    field :mode, :string
    belongs_to :respondent, Ask.Respondent
    field :respondent_hashed_number, :string
    belongs_to :channel, Ask.Channel
    field :disposition, :string
    # One of "prompt", "contact", "response" or "disposition changed"
    field :action_type, :string
    field :action_data, :string
    field :timestamp, :utc_datetime

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :survey_id,
      :mode,
      :respondent_id,
      :respondent_hashed_number,
      :channel_id,
      :disposition,
      :action_type,
      :action_data,
      :timestamp
    ])
    |> validate_required([
      :survey_id,
      :mode,
      :respondent_id,
      :respondent_hashed_number,
      :channel_id,
      :action_type,
      :timestamp
    ])
    |> foreign_key_constraint(:survey_id)
    |> foreign_key_constraint(:channel_id)
    |> foreign_key_constraint(:respondent_id)
  end
end
