defmodule Ask.Channel do
  use Ask.Model

  alias Ask.Repo
  alias Ask.Runtime.ChannelStatusServer

  schema "channels" do
    field :name, :string
    # valid types are:
    # * "sms"
    # * "ivr"
    field :type, :string
    field :provider, :string
    field :base_url, :string
    field :settings, :map
    field :patterns, Ask.Ecto.Type.JSON, default: []
    field :status, Ask.Ecto.Type.JSON, virtual: true
    belongs_to :user, Ask.User
    has_many :respondent_group_channels, Ask.RespondentGroupChannel, on_delete: :delete_all
    many_to_many :projects, Ask.Project, join_through: Ask.ProjectChannel, on_replace: :delete

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
    |> cast(params, [:name, :type, :provider, :base_url, :settings, :user_id, :patterns])
    |> validate_required([:name, :type, :provider, :settings, :user_id])
    |> validate_patterns
    |> assoc_constraint(:user)
  end

  # Deletes a channel and:
  # - marks related :ready surveys as :not_ready
  # - marks related :running surveys as :terminated with exit code 3
  def delete(channel) do
    surveys =
      Repo.all(
        from s in Ask.Survey,
          join: rgc in Ask.RespondentGroupChannel,
          join: rg in Ask.RespondentGroup,
          where: rgc.channel_id == ^channel.id,
          where: rg.id == rgc.respondent_group_id,
          where: s.id == rg.survey_id
      )

    Enum.each(surveys, fn survey ->
      case survey.state do
        :ready ->
          survey
          |> Ask.Survey.changeset(%{state: :not_ready})
          |> Repo.update!()

        :running ->
          Ask.Survey.cancel_respondents(survey)

          survey
          |> Ask.Survey.changeset(%{
            state: :terminated,
            exit_code: 3,
            exit_message: "Channel '#{channel.name}' no longer exists"
          })
          |> Repo.update!()

        _ ->
          :ok
      end
    end)

    Repo.delete(channel)
  end

  def with_status(channel) do
    status = channel.id |> ChannelStatusServer.get_channel_status()

    status =
      case status do
        :up -> %{status: "up"}
        :unknown -> %{status: "unknown"}
        down_or_error -> down_or_error
      end

    %{channel | status: status}
  end

  defp validate_patterns(changeset) do
    changeset
    |> validate_patterns_not_empty
    |> validate_equal_number_of_Xs
    |> validate_valid_characters
  end

  defp xs_count(pattern) do
    (String.split(pattern, "X") |> Enum.count()) - 1
  end

  defp valid_characters?(pattern) do
    Regex.match?(~r/^([0-9]|X|\(|\)|\+|\-| )*$/, pattern)
  end

  defp validate_patterns_not_empty(changeset) do
    patterns = get_field(changeset, :patterns, [])

    empty_pattern? = fn p ->
      Map.get(p, "input", "") == "" || Map.get(p, "output", "") == ""
    end

    if Enum.any?(patterns, empty_pattern?) do
      add_error(changeset, :patterns, "Pattern must not be blank")
    else
      changeset
    end
  end

  defp validate_equal_number_of_Xs(changeset) do
    patterns = get_field(changeset, :patterns, [])

    not_equal_xs? = fn p ->
      xs_count(Map.get(p, "input", "")) != xs_count(Map.get(p, "output", ""))
    end

    if Enum.any?(patterns, not_equal_xs?) do
      add_error(changeset, :patterns, "Number of X's doesn't match")
    else
      changeset
    end
  end

  defp validate_valid_characters(changeset) do
    patterns = get_field(changeset, :patterns, [])

    valid_characters_input_output? = fn p ->
      valid_characters?(Map.get(p, "input", "")) && valid_characters?(Map.get(p, "output", ""))
    end

    if Enum.all?(patterns, valid_characters_input_output?) do
      changeset
    else
      add_error(changeset, :patterns, "Invalid characters")
    end
  end
end
