defmodule Ask.User do
  use Ask.Web, :model
  use Coherence.Schema

  schema "users" do
    field :name, :string
    field :email, :string
    field :settings, Ask.Ecto.Type.JSON

    has_many :channels, Ask.Channel
    has_many :oauth_tokens, Ask.OAuthToken
    many_to_many :projects, Ask.Project, join_through: Ask.ProjectMembership, on_replace: :delete
    has_many :project_memberships, Ask.ProjectMembership

    coherence_schema()

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  @spec changeset(Ecto.Schema.t(), map()) :: Ecto.Changeset.t()
  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:name, :email, :settings] ++ coherence_fields())
    |> validate_required([:email])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
    |> add_settings_if_needed()
    |> validate_coherence(params)
  end

  @doc false
  @spec changeset(Ecto.Schema.t(), map(), atom) :: Ecto.Changeset.t()
  def changeset(model, params, :password) do
    model
    |> cast(
      params,
      ~w(password password_confirmation reset_password_token reset_password_sent_at)a
    )
    |> validate_coherence_password_reset(params)
  end

  def changeset(model, params, :registration) do
    changeset =
      changeset(model, params)
      |> add_settings_if_needed()

    if Config.get(:confirm_email_updates) && Map.get(params, "email", false) && model.id do
      changeset
      |> put_change(:unconfirmed_email, get_change(changeset, :email))
      |> delete_change(:email)
    else
      changeset
    end
  end

  defp add_settings_if_needed(changeset) do
    if !get_field(changeset, :settings) do
      changeset
      |> put_change(:settings, %{})
    else
      changeset
    end
  end
end
