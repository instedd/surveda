defmodule Ask.Survey do
  use Ask.Web, :model

  schema "surveys" do
    field :name, :string
    field :state, :string, default: "not_ready" # not_ready, ready, pending, completed
    field :cutoff, :integer
    field :respondents_count, :integer, virtual: true
    field :schedule_day_of_week, Ask.DayOfWeek, default: Ask.DayOfWeek.every_day
    field :schedule_start_time, Ecto.DateTime
    field :schedule_end_time, Ecto.DateTime

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
    |> cast(params, [:name, :project_id, :questionnaire_id, :state, :cutoff, :respondents_count, :schedule_day_of_week, :schedule_start_time, :schedule_end_time])
    |> validate_required([:name, :project_id, :state])
    |> foreign_key_constraint(:project_id)
  end

  def update_state(changeset) do
    state = get_field(changeset, :state)
    questionnaire_id = get_field(changeset, :questionnaire_id)
    respondents_count = get_field(changeset, :respondents_count)

    schedule = get_field(changeset, :schedule_day_of_week)
    [ _ | values ] = Map.values(schedule)
    schedule_completed = Enum.reduce(values, fn (x, acc) -> acc || x end)

    channels = get_field(changeset, :channels)

    changes = if state == "not_ready" && questionnaire_id && respondents_count && respondents_count > 0 && length(channels) > 0 && schedule_completed do
      Map.merge(changeset.changes, %{state: "ready"})
    else
      if state == "ready" && !(questionnaire_id && respondents_count && respondents_count > 0 && length(channels) > 0 && schedule_completed) do
        Map.merge(changeset.changes, %{state: "not_ready"})
      else
        changeset.changes
      end
    end

    changeset = Map.merge(changeset, %{changes: changes})

    changeset
  end
end
