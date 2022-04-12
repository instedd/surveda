defmodule Ask.ProjectMembership do
  use Ask.Model
  alias Ask.Repo

  schema "project_memberships" do
    # owner, admin, editor, reader
    field :level, :string
    belongs_to :user, Ask.User
    belongs_to :project, Ask.Project

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:user_id, :project_id, :level])
    |> validate_required([:user_id, :project_id, :level])
    |> validate_inclusion(:level, ["owner", "admin", "editor", "reader"])
    |> foreign_key_constraint(:user)
    |> foreign_key_constraint(:project)
  end

  def authorize(changeset, user_level) do
    new_level = get_change(changeset, :level)
    old_level = changeset.data.level

    if can_update(old_level, new_level, user_level) do
      changeset
    else
      raise AskWeb.UnauthorizedError
    end
  end

  # No one can change an user to owner
  def can_update(_, "owner", _) do
    false
  end

  # No one can change an owner to other level
  def can_update("owner", _, _) do
    false
  end

  # Except the previous two, an owner can perform all the other possible combinations
  def can_update(_, _, "owner") do
    true
  end

  # Same for admins
  def can_update(_, _, "admin") do
    true
  end

  # Only owner or admins can update an admin
  def can_update("admin", _, _) do
    false
  end

  # And only owner or admins can create new admin
  def can_update(_, "admin", _) do
    false
  end

  # For the remaining combinations, an editor can perform all
  def can_update(_, _, "editor") do
    true
  end

  # And everything else should be denied
  def can_update(_, _, _) do
    false
  end

  # Transforms pending invitations for a user into actual project memberships.
  def accept_pending_invitations(user) do
    invites = Repo.all(from i in Ask.Invite, where: i.email == ^user.email)

    Enum.each(invites, fn invite ->
      membership =
        changeset(%Ask.ProjectMembership{}, %{
          "user_id" => user.id,
          "project_id" => invite.project_id,
          "level" => invite.level
        })

      Repo.transaction(fn ->
        Repo.insert(membership)
        Repo.delete!(invite)
      end)
    end)
  end
end
