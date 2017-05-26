defmodule Ask.Channel do
  use Ask.Web, :model

  alias Ask.Repo

  schema "channels" do
    field :name, :string
    field :type, :string
    field :provider, :string
    field :base_url, :string
    field :settings, :map
    belongs_to :user, Ask.User
    has_many :respondent_group_channels, Ask.RespondentGroupChannel, on_delete: :delete_all

    timestamps()
  end

  @doc """
  Returns a new instance of the runtime channel implementation (Ask.Runtime.Channel)
  """
  def runtime_channel(channel) do
    provider(channel.provider).new(channel)
  end

  @doc """
  Returns the runtime chanel provider (module) by name
  """
  def provider(name) do
    channel_config = Application.get_env(:ask, :channel)
    channel_config[:providers][name]
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :type, :provider, :base_url, :settings, :user_id])
    |> validate_required([:name, :type, :provider, :settings, :user_id])
    |> assoc_constraint(:user)
  end

  # Deletes a channel and:
  # - marks related "ready" surveys as "not_ready"
  # - marks related "running" surveys as "terminated" with exit code 3
  def delete(channel) do
    surveys = Repo.all(from s in Ask.Survey,
      join: rgc in Ask.RespondentGroupChannel,
      join: rg in Ask.RespondentGroup,
      where: rgc.channel_id == ^channel.id,
      where: rg.id == rgc.respondent_group_id,
      where: s.id == rg.survey_id)

    Enum.each surveys, fn survey ->
      case survey.state do
        "ready" ->
          survey
          |> Ask.Survey.changeset(%{state: "not_ready"})
          |> Repo.update!
        "running" ->
          Ask.Survey.cancel_respondents(survey)

          survey
          |> Ask.Survey.changeset(%{state: "terminated", exit_code: 3, exit_message: "Channel '#{channel.name}' no longer exists"})
          |> Repo.update!
        _ ->
          :ok
      end
    end

    Repo.delete(channel)
  end
end
