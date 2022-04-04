defmodule Ask.Repo.Migrations.FillRespondentGroupsSampleAndRespondentsCount do
  use Ecto.Migration

  alias Ask.Repo

  defmodule RespondentGroup do
    use Ask.Web, :model

    schema "respondent_groups" do
      field :sample, Ask.Ecto.Type.JSON
      field :respondents_count, :integer

      Ecto.Schema.timestamps()
    end

    def changeset(struct, params \\ %{}) do
      struct
      |> cast(params, [:sample, :respondents_count])
      |> validate_required([:sample, :respondents_count])
    end
  end

  def change do
    groups = RespondentGroup |> Repo.all()

    groups
    |> Enum.each(fn group ->
      respondents_count =
        Repo.query!("select count(*) from respondents where respondent_group_id = #{group.id}").rows
        |> hd
        |> hd

      sample =
        Repo.query!(
          "select phone_number from respondents where respondent_group_id = #{group.id} limit 5"
        ).rows
        |> Enum.map(&hd(&1))

      group
      |> RespondentGroup.changeset(%{
        respondents_count: respondents_count,
        sample: sample
      })
      |> Repo.update!()
    end)
  end
end
