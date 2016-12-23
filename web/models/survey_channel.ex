defmodule Ask.SurveyChannel do
  use Ask.Web, :model

  schema "survey_channels" do
    belongs_to :survey, Ask.Survey
    belongs_to :channel, Ask.Channel

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:survey_id, :channel_id])
    |> validate_required([:survey_id, :channel_id])
    |> foreign_key_constraint(:survey)
    |> foreign_key_constraint(:channel)
  end
end
