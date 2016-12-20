defmodule Ask.Project do
  use Ask.Web, :model

  schema "projects" do
    field :name, :string

    has_many :questionnaires, Ask.Questionnaire
    has_many :surveys, Ask.Survey
    many_to_many :users, Ask.User, join_through: Ask.ProjectMembership, on_replace: :delete
    has_many :project_memberships, Ask.ProjectMembership

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name])
  end

  def touch!(project) do
    project
    |> Ask.Project.changeset
    |> Ask.Repo.update!(force: true)
  end
end
