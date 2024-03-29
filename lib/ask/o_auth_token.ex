defmodule Ask.OAuthToken do
  use Ask.Model

  schema "oauth_tokens" do
    field :provider, :string
    field :base_url, :string
    field :access_token, :map
    field :expires_at, :utc_datetime
    belongs_to :user, Ask.User

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:user_id, :provider, :base_url, :access_token, :expires_at])
    |> validate_required([:user_id, :provider, :access_token])
  end

  def from_access_token(struct, access_token) do
    expires_at = DateTime.from_unix!(access_token.expires_at)

    encoded_token =
      access_token
      |> Map.from_struct()
      # Stringify keys
      |> Enum.map(fn {k, v} -> {Atom.to_string(k), v} end)
      |> Enum.into(%{})

    struct
    |> changeset(%{access_token: encoded_token, expires_at: expires_at})
  end

  def access_token(token) do
    Poison.Decode.decode(token.access_token, as: %OAuth2.AccessToken{})
  end

  def about_to_expire?(token) do
    expires_at =
      if is_integer(token.expires_at) do
        DateTime.from_unix!(token.expires_at)
      else
        token.expires_at
      end
    limit = DateTime.now!("Etc/UTC") |> DateTime.add(60, :second)
    DateTime.compare(expires_at, limit) == :lt
  end
end
