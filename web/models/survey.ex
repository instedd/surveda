defmodule Ask.Survey do
  use Ask.Web, :model

  schema "surveys" do
    field :name, :string
    has_many :survey_channels, Ask.SurveyChannel
    has_many :channels, through: [:survey_channels, :channel]
    field :state, :string, default: "pending"
    belongs_to :project, Ask.Project
    belongs_to :questionnaire, Ask.Questionnaire
    field :cutoff, :integer

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
