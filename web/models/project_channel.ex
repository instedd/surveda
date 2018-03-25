defmodule Ask.ProjectChannel do
  use Ask.Web, :model

  schema "project_channels" do
    belongs_to :project, Ask.Project
    belongs_to :channel, Ask.Channel
    field :mode, :string

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:project_id, :channel_id, :mode])
    |> validate_required([:project_id, :channel_id, :mode])
    |> unique_constraint(:channel_id_project_id)
    |> foreign_key_constraint(:project)
    |> foreign_key_constraint(:channel)
  end
end
