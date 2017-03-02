defmodule Ask.SurveyLogEntry do
  use Ask.Web, :model

  schema "survey_log_entries" do
    field :survey_id, :integer
    field :mode, :string
    field :respondent, :string
    field :channel_id, :integer
    field :disposition, :string
    field :action_type, :string # One of "prompt", "contact" or "response"
    field :action_data, :string
    field :timestamp, Ecto.DateTime

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:survey_id, :mode, :respondent, :channel_id, :disposition, :action_type, :action_data, :timestamp])
    |> validate_required([:survey_id, :mode, :respondent, :channel_id, :disposition, :action_type, :action_data, :timestamp])
  end
end
