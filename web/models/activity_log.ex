defmodule Ask.ActivityLog do
  use Ask.Web, :model
  alias Ask.{ActivityLog, Project}

  schema "activity_log" do
    belongs_to :project, Ask.Project
    belongs_to :user, Ask.User
    field :entity_type, :string
    field :entity_id, :integer
    field :action, :string
    field :metadata, Ask.Ecto.Type.JSON

    timestamps()
  end

  def valid_actions("project"), do:
    ["create_invite", "edit_invite", "delete_invite", "edit_collaborator", "remove_collaborator"]

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:project_id, :user_id, :entity_id, :entity_type, :action, :metadata])
    |> validate_inclusion(:action, valid_actions(params[:entity_type] || struct.entity_type))
    |> validate_required([:project_id, :user_id, :entity_id, :entity_type, :action])
  end

  defp typeof(%Project{}), do: "project"

  defp create(action, project, user, entity, metadata) do
    ActivityLog.changeset(%ActivityLog{}, %{
      project_id: project.id,
      user_id: user.id,
      entity_type: typeof(entity),
      entity_id: entity.id,
      action: action,
      metadata: metadata
    })
  end

  def edit_collaborator(project, user, collaborator, old_role, new_role) do
    create("edit_collaborator", project, user, project, %{
      project_name: project.name,
      collaborator_email: collaborator.email,
      collaborator_name: collaborator.name,
      old_role: old_role,
      new_role: new_role
    })
  end

  def remove_collaborator(project, user, collaborator, role) do
    create("remove_collaborator", project, user, project, %{
      project_name: project.name,
      collaborator_email: collaborator.email,
      collaborator_name: collaborator.name,
      role: role
    })
  end

  def edit_invite(project, user, target_email, old_role, new_role) do
    create("edit_invite", project, user, project, %{
      project_name: project.name,
      collaborator_email: target_email,
      old_role: old_role,
      new_role: new_role
    })
  end

  def delete_invite(project, user, target_email, role) do
    create("delete_invite", project, user, project, %{
      project_name: project.name,
      collaborator_email: target_email,
      role: role
    })
  end

  def create_invite(project, user, target_email, role) do
    create("create_invite", project, user, project, %{
      project_name: project.name,
      collaborator_email: target_email,
      role: role
    })
  end
end
