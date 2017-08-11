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
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :email, :settings] ++ coherence_fields())
    |> validate_required([:email])
    |> unique_constraint(:email)
    |> validate_format(:email, ~r/@/)
    |> add_settings_if_needed
    |> validate_coherence(params)
  end

  defp add_settings_if_needed(changeset) do
    changeset = if !get_field(changeset, :settings) do
                  change(changeset, settings: %{})
                else
                  changeset
                end
    changeset
  end
end
