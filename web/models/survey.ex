defmodule Ask.Survey do
  use Ask.Web, :model

  schema "surveys" do
    field :name, :string
    field :state, :string, default: "pending"
    field :cutoff, :integer
    field :respondents_count, :integer, virtual: true

    has_many :survey_channels, Ask.SurveyChannel
    has_many :channels, through: [:survey_channels, :channel]

    belongs_to :project, Ask.Project
    belongs_to :questionnaire, Ask.Questionnaire

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :project_id, :questionnaire_id, :state, :cutoff])
    |> validate_required([:name, :project_id, :state])
    |> foreign_key_constraint(:project_id)
  end
end
