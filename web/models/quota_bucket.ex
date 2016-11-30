defmodule Ask.QuotaBucket do
  use Ask.Web, :model

  @max_int 2147483647

  schema "quota_buckets" do
    field :condition, Ask.Ecto.Type.JSON
    field :quota, :integer
    field :count, :integer, default: 0
    belongs_to :survey, Ask.Survey

    timestamps()
  end

  def build_changeset(survey, params) do
    Enum.map(params, fn param ->
      changeset(build_assoc(survey, :quota_buckets, param), param)
    end)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:condition, :survey_id, :quota, :count])
    |> validate_required([:condition, :survey_id])
    |> foreign_key_constraint(:survey_id)
    |> validate_number(:quota, greater_than_or_equal_to: 0, less_than: @max_int)
  end
end
