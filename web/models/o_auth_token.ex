defmodule Ask.OAuthToken do
  use Ask.Web, :model

  schema "oauth_tokens" do
    field :provider, :string
    field :access_token, :map
    belongs_to :user, Ask.User

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:user_id, :provider, :access_token])
    |> validate_required([:user_id, :provider, :access_token])
  end

  def access_token(token) do
    OAuth2.AccessToken.new(token.access_token)
  end
end
