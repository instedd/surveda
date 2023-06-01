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

  if Mix.env() == :test do
    def about_to_expire?(nil) do
      false
    end
  end

  def about_to_expire?(token) do
    limit = Timex.now() |> Timex.add(Timex.Duration.from_minutes(1))
    Timex.before?(token.expires_at, limit)
  end
end
