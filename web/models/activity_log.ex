defmodule Ask.ActivityLog do
  use Ask.Web, :model
  alias Ask.{Repo, ActivityLog}

  schema "activity_log" do
    belongs_to :project, Ask.Project
    belongs_to :user, Ask.User
    field :entity_type, :string
    field :entity_id, :integer
    field :action, :string
    field :metadata, Ask.Ecto.Type.JSON

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:project_id, :user_id, :entity_id, :entity_type, :action, :metadata])
    |> validate_required([:project_id, :user_id, :entity_id, :entity_type, :action])
  end

  def create(params) do
    %ActivityLog{}
    |> ActivityLog.changeset(params)
    |> Repo.insert!
  end
end
