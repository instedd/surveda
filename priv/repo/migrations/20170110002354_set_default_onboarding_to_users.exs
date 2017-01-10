defmodule Ask.Repo.Migrations.SetDefaultSettingsToUsers do
  use Ecto.Migration
  alias Ask.Repo

  defmodule User do
    use Ask.Web, :model

    schema "users" do
      field :settings, Ask.Ecto.Type.JSON
    end

    def changeset(struct, params \\ %{}) do
      struct
      |> cast(params, [:settings])
    end
  end

  def change do
    User |> Repo.all |> Enum.each(fn u ->
      u |> User.changeset(%{settings: %{}}) |> Repo.update
    end)
  end
end
