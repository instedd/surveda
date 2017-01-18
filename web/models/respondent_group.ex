defmodule Ask.RespondentGroup do
  use Ask.Web, :model

  schema "respondent_groups" do
    field :name, :string
    field :sample, Ask.Ecto.Type.JSON
    field :respondents_count, :integer
    belongs_to :survey, Ask.Survey
    has_many :respondents, Ask.Respondent

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :sample, :respondents_count])
    |> validate_required([:name, :sample, :respondents_count])
  end
end
