defmodule Ask.User do
  use Ask.Web, :model

  schema "users" do
    field :email, :string
    field :encrypted_password, :string
    field :onboarding, Ask.Ecto.Type.JSON

    has_many :channels, Ask.Channel
    has_many :oauth_tokens, Ask.OAuthToken
    many_to_many :projects, Ask.Project, join_through: Ask.ProjectMembership, on_replace: :delete
    has_many :project_memberships, Ask.ProjectMembership

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:email, :encrypted_password])
    |> validate_required([:email, :encrypted_password])
    |> unique_constraint(:email)
    |> validate_format(:email, ~r/@/)
  end
end
