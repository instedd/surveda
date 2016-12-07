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

  # Numeric condition
  def matches_condition?(value, [from, to]) when is_integer(from) and is_integer(to) do
    case Integer.parse(value) do
    {value, ""} ->
      from <= value && value <= to
    _ ->
      false
    end
  end

  def matches_condition?(value, [from_val, to_val]) do
    from = String.to_integer(from_val)
    to = String.to_integer(to_val)
    case Integer.parse(value) do
      {value, ""} ->
        from <= value && value <= to
      _ ->
        false
    end
  end

  # Text condition
  def matches_condition?(value, condition) do
    value == condition
  end
end
