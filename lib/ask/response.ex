defmodule Ask.Response do
  use Ask.Model

  schema "responses" do
    field :field_name, :string
    field :value, :string
    belongs_to :respondent, Ask.Respondent

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:field_name, :value])
    |> validate_required([:field_name, :value])
  end

  @doc """
  Builds a list of responses based on reply.stores
  """
  def build_from_reply(reply) do
    reply
    |> Ask.Runtime.Reply.stores()
    |> Enum.map(fn {field_name, value} -> %Ask.Response{field_name: field_name, value: value} end)
  end
end
