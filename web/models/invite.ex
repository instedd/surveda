defmodule Ask.Invite do
  use Ask.Web, :model

  schema "invites" do
    field :code, :string
    field :level, :string # reader, editor
    field :email, :string
    field :inviter_email, :string
    belongs_to :project, Ask.Project

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:code, :level, :email, :project_id, :inviter_email])
    |> validate_required([:code, :level])
    |> validate_inclusion(:level, ["admin", "editor", "reader"])
    |> unique_constraint(:project_id, name: :project_id)
  end

end
