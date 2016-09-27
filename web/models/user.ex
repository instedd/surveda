defmodule Ask.User do
  use Ask.Web, :model

  schema "users" do
    field :email, :string
    field :encrypted_password, :string

    has_many :projects, Ask.Project
    has_many :channels, Ask.Channel
    has_many :oauth_tokens, Ask.OAuthToken

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:email, :encrypted_password])
    |> validate_required([:email, :encrypted_password])
    |> validate_format(:email, ~r/@/)
  end
end
