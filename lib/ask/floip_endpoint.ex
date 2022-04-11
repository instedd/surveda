defmodule Ask.FloipEndpoint do
  use AskWeb, :model

  schema "floip_endpoints" do
    field :name, :string
    field :uri, :string
    field :last_pushed_response_id, :integer
    field :retries, :integer

    # disabled | enabled | terminated
    field :state, :string, default: "enabled"
    field :auth_token, :string, default: ""

    belongs_to :survey, Ask.Survey

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :uri, :auth_token])
  end
end
