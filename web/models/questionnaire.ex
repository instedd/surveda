defmodule Ask.Questionnaire do
  defmodule Modes do
    @moduledoc """
    A custom type to map questionnaires modes to the database, because
    MySQL doesn't support arrays.

    This type maps from an array of strings to strings, joined by comma.
    """
    @behaviour Ecto.Type
    def type, do: :string

    def cast(list) when is_list(list), do: {:ok, list}
    def cast(_), do: :error

    def load(string) when is_binary(string), do: {:ok, String.split(string, ",")}

    def dump(list) when is_list(list), do: {:ok, Enum.join(list, ",")}
    def dump(_), do: :error
  end

  use Ask.Web, :model

  schema "questionnaires" do
    field :name, :string
    field :modes, Modes
    belongs_to :project, Ask.Project

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:project_id, :name, :modes])
    |> validate_required([:project_id, :name, :modes])
    |> foreign_key_constraint(:project_id)
  end
end
