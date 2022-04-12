defmodule Ask.QuotaBucket do
  use Ask.Model

  @max_int 2_147_483_647

  schema "quota_buckets" do
    field :condition, Ask.Ecto.Type.JSON
    field :quota, :integer
    field :count, :integer, default: 0
    belongs_to :survey, Ask.Survey

    timestamps()
  end

  def build_changeset(survey, params) do
    quotas_with_conditions_by_store =
      params
      |> Enum.map(fn quota ->
        %{quota | "condition" => index_by_store(quota["condition"])}
      end)

    Enum.map(quotas_with_conditions_by_store, fn quota ->
      changeset(build_assoc(survey, :quota_buckets, quota), quota)
    end)
  end

  def index_by_store(conditions) do
    conditions
    |> Enum.reduce(%{}, fn condition, conditions_by_store ->
      Map.put(conditions_by_store, condition["store"], condition["value"])
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

  def matches_condition?(value, [from, to]) do
    matches_condition?(value, [String.to_integer(from), String.to_integer(to)])
  end

  # Text condition
  def matches_condition?(value, condition) do
    value == condition
  end
end
