defmodule Ask.Repo.Migrations.PopulateSaltFieldInProjects do
  use Ecto.Migration

  alias Ask.Repo

  defmodule Project do
    use Ask.Web, :model

    schema "projects" do
      field :salt, :string
    end

    def changeset(struct, params \\ %{}) do
      struct
      |> cast(params, [:salt])
    end
  end

  def up do
    Project
    |> Repo.all()
    |> Enum.each(fn p ->
      salt = Ecto.UUID.generate()
      p |> Project.changeset(%{salt: salt}) |> Repo.update()
    end)
  end

  def down do
    Project
    |> Repo.all()
    |> Enum.each(fn p ->
      salt = nil
      p |> Project.changeset(%{salt: salt}) |> Repo.update()
    end)
  end
end
