defmodule Ask.Repo.Migrations.ChangeSurveyModesToAraryOfArrays do
  use Ecto.Migration

  alias Ask.Repo

  defmodule Survey do
    use Ask.Web, :model

    schema "surveys" do
      field :mode, Ask.Ecto.Type.JSON
    end

    def changeset(struct, params \\ %{}) do
      struct
      |> cast(params, [:mode])
    end
  end

  def change do
    Survey
    |> Repo.all()
    |> Enum.each(fn survey ->
      survey
      |> Survey.changeset(%{mode: [survey.mode || []]})
      |> Repo.update!()
    end)
  end
end
