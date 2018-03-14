defmodule Ask.ActivityLog do
  use Ask.Web, :model
  import User.Helper
  alias Ask.{ActivityLog, Project, Survey}

  schema "activity_log" do
    belongs_to :project, Ask.Project
    belongs_to :user, Ask.User
    field :entity_type, :string
    field :entity_id, :integer
    field :action, :string
    field :metadata, Ask.Ecto.Type.JSON
    field :remote_ip, :string

    timestamps()
  end

  def valid_actions("project"), do:
    ["create_invite", "edit_invite", "delete_invite", "edit_collaborator", "remove_collaborator"]

  def valid_actions("survey"), do:
    ["download", "enable_public_link", "regenerate_public_link", "disable_public_link"]

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:project_id, :user_id, :entity_id, :entity_type, :action, :metadata, :remote_ip])
    |> validate_inclusion(:action, valid_actions(params[:entity_type] || struct.entity_type))
    |> validate_required([:project_id, :entity_id, :entity_type, :action, :remote_ip])
  end

  defp typeof(%Project{}), do: "project"
  defp typeof(%Survey{}), do: "survey"

  defp create(action, project, conn, entity, metadata) do
    user_id = case current_user(conn) do
      nil -> nil
      user -> user.id
    end

    ActivityLog.changeset(%ActivityLog{}, %{
      project_id: project.id,
      user_id: user_id,
      entity_type: typeof(entity),
      entity_id: entity.id,
      remote_ip: :inet_parse.ntoa(conn.remote_ip) |> to_string,
      action: action,
      metadata: metadata
    })
  end

  defp report_type_from(target_name) do
    case target_name do
      "results" -> "survey_results"
      target_name -> target_name
    end
  end

  def edit_collaborator(project, conn, collaborator, old_role, new_role) do
    create("edit_collaborator", project, conn, project, %{project_name: project.name,
      collaborator_email: collaborator.email,
      collaborator_name: collaborator.name,
      old_role: old_role,
      new_role: new_role
    })
  end

  def remove_collaborator(project, conn, collaborator, role) do
    create("remove_collaborator", project, conn, project, %{
      project_name: project.name,
      collaborator_email: collaborator.email,
      collaborator_name: collaborator.name,
      role: role
    })
  end

  def edit_invite(project, conn, target_email, old_role, new_role) do
    create("edit_invite", project, conn, project, %{
      project_name: project.name,
      collaborator_email: target_email,
      old_role: old_role,
      new_role: new_role
    })
  end

  def delete_invite(project, conn, target_email, role) do
    create("delete_invite", project, conn, project, %{
      project_name: project.name,
      collaborator_email: target_email,
      role: role
    })
  end

  def create_invite(project, conn, target_email, role) do
    create("create_invite", project, conn, project, %{
      project_name: project.name,
      collaborator_email: target_email,
      role: role
    })
  end

  def download(project, conn, survey, report_type) do
    create("download", project, conn, survey, %{
      survey_name: survey.name,
      report_type: report_type
    })
  end

  def enable_public_link(project, conn, survey, target_name) do
    create("enable_public_link", project, conn, survey, %{
      survey_name: survey.name,
      report_type: report_type_from(target_name)
    })
  end

  def regenerate_public_link(project, conn, survey, target_name) do
    create("regenerate_public_link", project, conn, survey, %{
      survey_name: survey.name,
      report_type: report_type_from(target_name)
    })
  end

  def disable_public_link(project, conn, survey, link) do
    create("disable_public_link", project, conn, survey, %{
      survey_name: survey.name,
      report_type: report_type_from(link.name |> String.split("/") |> List.last)
    })
  end
end
