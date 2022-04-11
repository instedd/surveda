defmodule Ask.PanelSurvey do
  use AskWeb, :model
  alias __MODULE__

  alias Ask.{
    Folder,
    Project,
    Repo,
    Survey,
    SystemTime
  }

  alias Ask.Runtime.SurveyAction

  schema "panel_surveys" do
    field(:name, :string)
    belongs_to(:project, Project)
    belongs_to(:folder, Folder)

    has_many(:waves, Survey)

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :project_id, :folder_id])
    |> validate_required([:name, :project_id])
    |> foreign_key_constraint(:project_id)
    |> foreign_key_constraint(:folder_id)
  end

  @doc """
  Returns the list of panel_surveys.

  ## Examples

      iex> list_panel_surveys()
      [%PanelSurvey{}, ...]

  """
  def list_panel_surveys do
    Repo.all(PanelSurvey)
  end

  @doc """
  Gets a single panel_survey.

  Raises `Ecto.NoResultsError` if the Panel survey does not exist.

  ## Examples

      iex> get_panel_survey!(123)
      %PanelSurvey{}

      iex> get_panel_survey!(456)
      ** (Ecto.NoResultsError)

  """
  def get_panel_survey!(id), do: Repo.get!(PanelSurvey, id)

  def create_panel_survey(attrs) do
    %PanelSurvey{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a panel_survey.

  ## Examples

      iex> update_panel_survey(panel_survey, %{field: new_value})
      {:ok, %PanelSurvey{}}

      iex> update_panel_survey(panel_survey, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

  def update_panel_survey(%{project_id: current} = _panel_survey, %{project_id: new} = _attrs)
      when current != new do
    {:error, "Project can't be changed"}
  end

  def update_panel_survey(%PanelSurvey{} = panel_survey, attrs) do
    panel_survey
    |> changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a PanelSurvey.

  ## Examples

      iex> delete_panel_survey(panel_survey)
      {:ok, %PanelSurvey{}}

      iex> delete_panel_survey(panel_survey)
      {:error, %Ecto.Changeset{}}

  """
  def delete_panel_survey(%PanelSurvey{} = panel_survey) do
    Repo.preload(panel_survey, :waves).waves
    |> Enum.each(fn survey -> SurveyAction.delete(survey, nil) end)

    Repo.delete(panel_survey)
  end

  def latest_wave(panel_survey) do
    Repo.preload(panel_survey, :waves).waves
    |> List.last()
  end

  def updated_at(panel_survey) do
    Repo.preload(panel_survey, :waves).waves
    |> Enum.map(fn %{updated_at: updated_at} -> updated_at end)
    |> Enum.concat([panel_survey.updated_at])
    |> Enum.max()
  end

  def repeatable?(panel_survey) do
    latest_wave(panel_survey)
    |> Survey.terminated?()
  end

  def new_wave_name() do
    now_yyyy_mm_dd()
  end

  def new_panel_survey_name(nil = _survey_name), do: "Panel Survey #{now_yyyy_mm_dd()}"
  def new_panel_survey_name(survey_name), do: survey_name

  defp now_yyyy_mm_dd(), do: SystemTime.time().now |> Timex.format!("{YYYY}-{0M}-{D}")
end
