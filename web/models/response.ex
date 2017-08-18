defmodule Ask.Response do
  use Ask.Web, :model

  schema "responses" do
    field :field_name, :string
    field :value, :string
    belongs_to :respondent, Ask.Respondent

    timestamps(type: :utc_datetime)
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:field_name, :value])
    |> validate_required([:field_name, :value])
  end
end
