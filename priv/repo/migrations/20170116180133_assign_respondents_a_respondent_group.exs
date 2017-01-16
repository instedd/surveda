defmodule Ask.Repo.Migrations.AssignRespondentsARespondentGroup do
  use Ecto.Migration

  alias Ask.Repo

  defmodule RespondentGroup do
    use Ask.Web, :model

    schema "respondent_groups" do
      field :name, :string
      field :survey_id, :integer
      Ecto.Schema.timestamps()
    end

    def changeset(struct, params \\ %{}) do
      struct
      |> cast(params, [:name, :survey_id])
      |> validate_required([:name, :survey_id])
    end
  end

  def change do
    # Traverse all surveys
    Repo.query!("select id from surveys").rows |> Enum.each(fn [survey_id] ->
      # Check if the survey has respondents
      respondents_count =
        Repo.query!("select count(*) from respondents where survey_id = #{survey_id}").rows |> hd |> hd

      if respondents_count > 0 do
        # Create a new respondent group for this survey
        group = %RespondentGroup{
          name: "Group",
          survey_id: survey_id,
        } |> Repo.insert!

        # Assign the group to all respondents in the survey
        Repo.query!("update respondents set respondent_group_id = #{group.id} where survey_id = #{survey_id}")
      end
    end)
  end
end
