defmodule Ask.Questionnaire do
  use Ask.Web, :model

  alias Ask.{Questionnaire, QuestionnaireVariable, Repo}

  schema "questionnaires" do
    field :name, :string
    field :modes, Ask.Ecto.Type.StringList
    field :steps, Ask.Ecto.Type.JSON
    field :quota_completed_steps, Ask.Ecto.Type.JSON
    field :settings, Ask.Ecto.Type.JSON
    field :languages, Ask.Ecto.Type.JSON
    field :default_language, :string
    field :valid, :boolean
    belongs_to :snapshot_of_questionnaire, Ask.Questionnaire, foreign_key: :snapshot_of
    belongs_to :project, Ask.Project
    has_many :questionnaire_variables, Ask.QuestionnaireVariable, on_delete: :delete_all
    has_many :translations, Ask.Translation, on_delete: :delete_all

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:project_id, :name, :modes, :steps, :quota_completed_steps, :languages, :default_language, :valid, :settings, :snapshot_of])
    |> validate_required([:project_id, :modes, :steps, :settings])
    |> foreign_key_constraint(:project_id)
    |> foreign_key_constraint(:snapshot_of)
  end

  def recreate_variables!(questionnaire) do
    # Get existing variables
    existing_variables = (from v in QuestionnaireVariable,
      where: v.questionnaire_id == ^questionnaire.id)
    |> Repo.all

    # Get new names
    new_names = questionnaire
    |> all_steps
    |> Enum.map(&Map.get(&1, "store"))
    |> Enum.reject(fn store -> store == nil end)
    |> Enum.uniq

    # Compute additions
    additions = new_names
    |> Enum.reject(fn name ->
      existing_variables
      |> Enum.any?(fn var -> var.name == name end)
    end)

    # Compute deletions
    deletions = existing_variables
    |> Enum.reject(fn var ->
      new_names
      |> Enum.any?(fn name -> name == var.name end)
    end)

    # Insert additions
    additions |> Enum.each(fn name ->
      var = %QuestionnaireVariable{
        project_id: questionnaire.project_id,
        questionnaire_id: questionnaire.id,
        name: name,
      }
      var |> Repo.insert!
    end)

    # Delete deletions
    deletions |> Enum.each(fn var ->
      var
      |> Repo.delete!
    end)

    questionnaire
  end

  def sms_split_separator, do: "\u{1E}"

  def variables(questionnaire = %Questionnaire{}) do
    variables(all_steps(questionnaire))
  end

  def variables(steps) when is_list(steps) do
    steps
    |> Enum.map(&variables/1)
    |> Enum.reject(fn x -> x == nil end)
    |> Enum.uniq
  end

  def variables(%{"store" => var}) do
    var
  end

  def variables(_) do
    nil
  end

  def all_steps(%Questionnaire{steps: steps, quota_completed_steps: nil}) do
    steps
  end

  def all_steps(%Questionnaire{steps: steps, quota_completed_steps: quota_completed_steps}) do
    steps ++ quota_completed_steps
  end
end
