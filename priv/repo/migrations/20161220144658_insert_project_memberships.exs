defmodule Ask.Repo.Migrations.InsertProjectMemberships do
  use Ecto.Migration
  alias Ask.Repo

  defmodule Project do
    use Ask.Web, :model

    schema "projects" do
      belongs_to :user, Ask.User
    end
  end

  defmodule ProjectMembership do
    use Ask.Web, :model

    schema "project_memberships" do
      field :level, :string
      belongs_to :user, Ask.User
      belongs_to :project, Ask.Project

      Ecto.Schema.timestamps()
    end

    def changeset(struct, params \\ %{}) do
      struct
      |> cast(params, [:user_id, :project_id, :level])
    end
  end

  def change do
    Ask.Repo.transaction(fn ->
      Project
      |> Repo.all()
      |> Enum.each(fn p ->
        ProjectMembership.changeset(%ProjectMembership{}, %{
          project_id: p.id,
          user_id: p.user_id,
          level: "owner"
        })
        |> Repo.insert()
      end)
    end)
  end
end
