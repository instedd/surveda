defmodule Ask.User do
  use Ask.Web, :model
  use Coherence.Schema

  schema "users" do
    field :name, :string
    field :email, :string

    has_many :channels, Ask.Channel
    has_many :oauth_tokens, Ask.OAuthToken
    many_to_many :projects, Ask.Project, join_through: Ask.ProjectMembership, on_replace: :delete
    has_many :project_memberships, Ask.ProjectMembership

    coherence_schema

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :email] ++ coherence_fields)
    |> validate_required([:email])
    |> unique_constraint(:email)
    |> validate_format(:email, ~r/@/)
    |> validate_coherence(params)
  end
end
