defmodule Ask.Repo.Migrations.PopulateProjectChannels do
  use Ecto.Migration
  alias Ask.Repo
  import Ecto.Query

  defmodule ProjectChannel do
    use Ask.Web, :model

    schema "project_channels" do
      belongs_to :channel, Channel
      belongs_to :project, Project

      Ecto.Schema.timestamps()
    end

    def changeset(struct, params \\ %{}) do
      struct
      |> cast(params, [:channel_id, :project_id])
      |> unique_constraint(:channel_id_project_id)
    end
  end

  defmodule Survey do
    use Ask.Web, :model

    schema "surveys" do
      has_many :respondent_groups, RespondentGroup
      belongs_to :project, Project

      Ecto.Schema.timestamps()
    end
  end

  defmodule RespondentGroup do
    use Ask.Web, :model

    schema "respondent_groups" do
      belongs_to :survey, Survey
      has_many :respondent_group_channels, RespondentGroupChannel, on_delete: :delete_all
      many_to_many :channels, Channel, join_through: RespondentGroupChannel, on_replace: :delete

      Ecto.Schema.timestamps()
    end
  end

  defmodule RespondentGroupChannel do
    use Ask.Web, :model

    schema "respondent_group_channels" do
      belongs_to :respondent_group, RespondentGroup
      belongs_to :channel, Channel

      Ecto.Schema.timestamps()
    end
  end

  def up do
    Repo.transaction fn ->
      RespondentGroupChannel |> preload([respondent_group: :survey])|> Repo.all |> Enum.each(fn rgc ->
        ProjectChannel.changeset(%ProjectChannel{}, %{project_id: rgc.respondent_group.survey.project_id, channel_id: rgc.channel_id})
          |> Repo.insert(on_conflict: :nothing)
      end)
    end
  end

  def down do
  end
end
