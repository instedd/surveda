defmodule Ask.RespondentGroup do
  use Ask.Web, :model

  schema "respondent_groups" do
    field :name, :string
    belongs_to :survey, Ask.Survey
    has_many :respondents, Ask.Respondent

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name])
    |> validate_required([:name])
  end
end
