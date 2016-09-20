defmodule Ask.Survey do
  use Ask.Web, :model

  schema "surveys" do
    field :name, :string
    field :state, :string, default: "not_ready" # not_ready, ready, pending, completed
    field :cutoff, :integer
    field :respondents_count, :integer, virtual: true

    many_to_many :channels, Ask.Channel, join_through: Ask.SurveyChannel, on_replace: :delete
    has_many :respondents, Ask.Respondent

    belongs_to :project, Ask.Project
    belongs_to :questionnaire, Ask.Questionnaire

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :project_id, :questionnaire_id, :state, :cutoff, :respondents_count])
    |> validate_required([:name, :project_id, :state])
    |> foreign_key_constraint(:project_id)
  end

  def update_state(changeset) do
    state = get_field(changeset, :state)
    questionnaire_id = get_field(changeset, :questionnaire_id)
    cutoff = get_field(changeset, :cutoff)
    respondents_count = get_field(changeset, :respondents_count)

    channels = get_field(changeset, :channels)

    changes = if state == "not_ready" && questionnaire_id && cutoff && respondents_count && respondents_count > 0 && length(channels) > 0 do
      Map.merge(changeset.changes, %{state: "ready"})
    else
      if state == "ready" && !(questionnaire_id && cutoff && respondents_count && respondents_count > 0 && length(channels) > 0) do
        Map.merge(changeset.changes, %{state: "not_ready"})
      else
        changeset.changes
      end
    end

    changeset = Map.merge(changeset, %{changes: changes})

    changeset
  end
end
