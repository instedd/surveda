defmodule Ask.Project do
  use Ask.Model

  schema "projects" do
    field :name, :string
    field :salt, :string
    field :colour_scheme, :string
    field :timezone, :string
    field :initial_success_rate, :float
    field :eligibility_rate, :float
    field :response_rate, :float
    field :valid_respondent_rate, :float
    field :batch_limit_per_minute, :integer
    field :archived, :boolean, default: false

    has_many :questionnaires, Ask.Questionnaire
    has_many :surveys, Ask.Survey
    has_many :folders, Ask.Folder
    has_many :panel_surveys, Ask.PanelSurvey
    many_to_many :users, Ask.User, join_through: Ask.ProjectMembership, on_replace: :delete
    has_many :project_memberships, Ask.ProjectMembership
    many_to_many :channels, Ask.Channel, join_through: Ask.ProjectChannel, on_replace: :delete
    has_many :project_channels, Ask.ProjectChannel
    has_many :activity_logs, Ask.ActivityLog

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :name,
      :salt,
      :colour_scheme,
      :timezone,
      :archived,
      :initial_success_rate,
      :eligibility_rate,
      :response_rate,
      :valid_respondent_rate,
      :batch_limit_per_minute
    ])
    |> validate_colour_scheme
    |> validate_rate(:initial_success_rate)
    |> validate_rate(:eligibility_rate)
    |> validate_rate(:response_rate)
    |> validate_rate(:valid_respondent_rate)
    |> validate_positive
  end

  def touch!(project) do
    project
    |> Ask.Project.changeset()
    |> Ask.Repo.update!(force: true)
  end

  defp validate_colour_scheme(changeset) do
    colour_scheme = get_field(changeset, :colour_scheme)

    cond do
      colour_scheme && !Enum.member?(["default", "better_data_for_health"], colour_scheme) ->
        add_error(
          changeset,
          :colour_scheme,
          "value has to be either default or better_data_for_health"
        )

      true ->
        changeset
    end
  end

  defp validate_rate(changeset, rate) do
    rate_field = get_field(changeset, rate)

    cond do
      rate_field && (rate_field < 0 || rate_field > 1) ->
        add_error(changeset, rate, "value has to be between 0 and 1")

      true ->
        changeset
    end
  end

  defp validate_positive(changeset) do
    batch_limit_per_minute = get_field(changeset, :batch_limit_per_minute)

    cond do
      batch_limit_per_minute && batch_limit_per_minute < 0 ->
        add_error(changeset, :batch_limit_per_minute, "value has to be positive")

      true ->
        changeset
    end
  end
end
