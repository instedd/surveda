defmodule Ask.Repo.Migrations.SetDefaultOnboardingToUsers do
  use Ecto.Migration
  alias Ask.Repo

  defmodule User do
    use Ask.Web, :model

    schema "users" do
      field :onboarding, Ask.Ecto.Type.JSON
    end

    def changeset(struct, params \\ %{}) do
      struct
      |> cast(params, [:onboarding])
    end
  end

  def change do
    User |> Repo.all |> Enum.each(fn u ->
      u |> User.changeset(%{onboarding: %{}}) |> Repo.update
    end)
  end
end
