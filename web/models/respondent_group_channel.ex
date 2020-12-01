defmodule Ask.RespondentGroupChannel do
  use Ask.Web, :model

  schema "respondent_group_channels" do
    belongs_to :respondent_group, Ask.RespondentGroup
    belongs_to :channel, Ask.Channel
    # valid modes are:
    # * "sms"
    # * "ivr"
    # * "mobileweb"
    field :mode, :string

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:respondent_group_id, :channel_id, :mode])
    |> validate_required([:respondent_group_id, :channel_id, :mode])
    |> foreign_key_constraint(:respondent_group)
    |> foreign_key_constraint(:channel)
  end
end
