defmodule Ask.Questionnaire do
  use Ask.Web, :model

  schema "questionnaires" do
    field :name, :string
    field :modes, Ask.Ecto.Type.StringList
    field :steps, Ask.Ecto.Type.JSON
    belongs_to :project, Ask.Project

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:project_id, :name, :modes, :steps])
    |> validate_required([:project_id, :name, :modes, :steps])
    |> foreign_key_constraint(:project_id)
  end
end
