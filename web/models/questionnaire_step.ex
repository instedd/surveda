defmodule Ask.QuestionnaireStep do
  use Ask.Web, :model

  schema "questionnaire_steps" do
    field :type, :string
    field :settings, :map
    belongs_to :questionnaire, Ask.Questionnaire

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:type, :settings])
    |> validate_required([:type, :settings])
  end
end
