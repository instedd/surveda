defmodule Ask.Session do
  use AskWeb, :model

  schema "sessions" do
    field :token, :string
    field :user_type, :string
    field :user_id, :string
    timestamps()
  end

  @fields ~w(token user_type user_id)a

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @fields)
    |> validate_required(@fields)
    |> unique_constraint(:token)
  end
end
