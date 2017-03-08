defmodule Ask.Questionnaire do
  use Ask.Web, :model

  alias Ask.{QuestionnaireVariable, Repo}

  schema "questionnaires" do
    field :name, :string
    field :modes, Ask.Ecto.Type.StringList
    field :steps, Ask.Ecto.Type.JSON
    field :quota_completed_msg, Ask.Ecto.Type.JSON
    field :error_msg, Ask.Ecto.Type.JSON
    field :mobile_web_sms_message, :string
    field :languages, Ask.Ecto.Type.JSON
    field :default_language, :string
    belongs_to :project, Ask.Project
    has_many :questionnaire_variables, Ask.QuestionnaireVariable, on_delete: :delete_all

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:project_id, :name, :modes, :steps, :languages, :default_language, :quota_completed_msg, :error_msg])
    |> validate_required([:project_id, :modes, :steps])
    |> foreign_key_constraint(:project_id)
  end

  def recreate_variables!(questionnaire) do
    # Get existing variables
    existing_variables = (from v in QuestionnaireVariable,
      where: v.questionnaire_id == ^questionnaire.id)
    |> Repo.all

    # # Delete previous variables
    # (from v in QuestionnaireVariable,
    #   where: v.questionnaire_id == ^questionnaire.id)
    # |> Repo.delete_all

    # Get new names
    new_names = questionnaire.steps
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
  end

  def sms_split_separator, do: "\u{1E}"
end
