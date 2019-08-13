defmodule Ask.Folder do
  use Ask.Web, :model

  schema "folders" do
    field :name, :string
    has_many :surveys, Ask.Survey

    belongs_to :project, Ask.Project
    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :project_id])
    |> validate_required([:name, :project_id])
    |> unique_constraint(:name, name: :folders_name_project_id_index)
  end

  def delete_changeset(folder) do
    folder
    |> change()
    |> no_assoc_constraint(:surveys, message: "There are still surveys in this folder")
  end
end
