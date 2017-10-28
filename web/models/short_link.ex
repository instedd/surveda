defmodule Ask.ShortLink do
  use Ask.Web, :model
  alias __MODULE__
  alias Ask.Repo

  schema "short_links" do
    field :hash, :string
    field :name, :string
    field :target, :string

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:hash, :name, :target])
    |> validate_required([:hash, :name, :target])
  end

  def generate_link(name, target) do
    case Repo.get_by(ShortLink, name: name) do
      nil ->
        %ShortLink{
          name: name,
          target: target,
          hash: random_hash()
        }
        |> Repo.insert
      link -> {:ok, link}
    end
  end

  def regenerate(%ShortLink{} = link) do
    change(link, %{hash: random_hash()})
    |> Repo.update
  end

  defp random_hash do
    String.slice(:crypto.hash(:md5, Ecto.UUID.generate) |> Base.encode16(case: :lower), -32, 32)
  end
end
