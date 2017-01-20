defmodule Ask.Repo.Migrations.MoveSurveyChannelsToRespondentGroupChannels do
  use Ecto.Migration

  alias Ask.Repo

  defmodule RespondentGroupChannel do
    use Ask.Web, :model

    schema "respondent_group_channels" do
      field :respondent_group_id, :integer
      field :channel_id, :integer

      Ecto.Schema.timestamps()
    end

    def changeset(struct, params \\ %{}) do
      struct
      |> cast(params, [:respondent_group_id, :channel_id])
      |> validate_required([:respondent_group_id, :channel_id])
    end
  end

  def up do
    Repo.query!("select survey_id, channel_id from survey_channels").rows
    |> Enum.each(fn [survey_id, channel_id] ->
      rows = Repo.query!("select id from respondent_groups where survey_id = #{survey_id} limit 1").rows
      if length(rows) == 1 do
        respondent_group_id = hd(hd(rows))
        %RespondentGroupChannel{
          respondent_group_id: respondent_group_id,
          channel_id: channel_id,
        } |> Repo.insert!
      end
    end)
  end

  def down do
    Repo.query!("delete from respondent_groups")
  end
end
