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

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:project_id, :name, :modes, :steps, :languages, :default_language])
    |> validate_required([:project_id, :modes, :steps])
    |> foreign_key_constraint(:project_id)
  end
end
