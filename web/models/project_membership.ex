defmodule Ask.ProjectMembership do
  use Ask.Web, :model

  schema "project_memberships" do
    field :level, :string # owner, editor, reader
    belongs_to :user, Ask.User
    belongs_to :project, Ask.Project

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:user_id, :project_id, :level])
    |> validate_required([:user_id, :project_id, :level])
    |> foreign_key_constraint(:user)
    |> foreign_key_constraint(:project)
  end
end
