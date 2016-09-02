defmodule Ask.Questionnaire do
  use Ask.Web, :model

  schema "questionnaires" do
    field :name, :string
    field :description, :string
    belongs_to :project, Ask.Project

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :description])
    |> validate_required([:name, :description])
  end
end
