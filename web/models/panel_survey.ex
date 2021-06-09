defmodule Ask.PanelSurvey do
  use Ask.Web, :model
  alias __MODULE__

  alias Ask.{
    Folder,
    Project,
    Repo,
    Survey
  }

  schema "panel_surveys" do
    field(:name, :string)
    belongs_to(:project, Project)
    belongs_to(:folder, Folder)
    has_many(:occurrences, Survey)

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

  @doc """
  Creates a panel_survey.

  ## Examples

      iex> create_panel_survey(%{field: value})
      {:ok, %PanelSurvey{}}

      iex> create_panel_survey(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_panel_survey(attrs \\ %{}) do
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
    Repo.delete(panel_survey)
  end
end
