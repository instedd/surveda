defmodule Ask.CompletedRespondents do
  use Ask.Model

  @primary_key false
  schema "completed_respondents" do
    belongs_to :survey, Ask.Survey, primary_key: true
    field :questionnaire_id, :integer, primary_key: true
    field :quota_bucket_id, :integer, primary_key: true
    field :mode, :string, primary_key: true
    field :date, :date, primary_key: true
    field :count, :integer
  end
end
