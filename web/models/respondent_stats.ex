defmodule Ask.RespondentStats do
  use Ask.Web, :model

  schema "respondent_stats" do
    belongs_to :survey, Ask.Survey
    field :questionnaire_id, :integer
    field :state, :string
    field :disposition, :string
    field :quota_bucket_id, :integer
    field :mode, :string
    field :count, :integer
  end
end
