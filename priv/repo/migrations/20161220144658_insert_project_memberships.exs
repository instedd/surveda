defmodule Ask.Repo.Migrations.InsertProjectMemberships do
  use Ecto.Migration
  alias Ask.Repo
  alias Ask.Project
  alias Ask.ProjectMembership

  def change do
    Ask.Repo.transaction fn ->
      Project |> Repo.all |> Enum.each(fn p ->
        changeset = ProjectMembership.changeset(%ProjectMembership{}, %{project_id: p.id, user_id: p.user_id, level: "owner"})
        Repo.insert(changeset)
      end)
    end
  end
end
