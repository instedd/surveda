defmodule Ask.Questionnaire do
  use Ask.Web, :model

  schema "questionnaires" do
    field :name, :string
    field :modes, Ask.Ecto.Type.StringList
    field :steps, Ask.Ecto.Type.JSON
    field :quota_completed_msg, Ask.Ecto.Type.JSON
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
    |> cast(params, [:project_id, :name, :modes, :steps, :languages, :default_language, :quota_completed_msg])
    |> validate_required([:project_id, :modes, :steps])
    |> foreign_key_constraint(:project_id)
  end

  def recreate_variables!(questionnaire) do
    # Delete previous variables
    (from v in Ask.QuestionnaireVariable,
      where: v.questionnaire_id == ^questionnaire.id)
    |> Ask.Repo.delete_all

    # Get step stores
    stores = questionnaire.steps
    |> Enum.map(&Map.get(&1, "store"))
    |> Enum.reject(fn store -> store == nil end)
    |> Enum.uniq

    # Create a variable for each store
    stores
    |> Enum.each(fn store ->
      var = %Ask.QuestionnaireVariable{
        project_id: questionnaire.project_id,
        questionnaire_id: questionnaire.id,
        name: store,
      }
      var |> Ask.Repo.insert!
    end)
  end
end
