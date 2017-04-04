defmodule Ask.Repo.Migrations.SetDefaultBaseUrlToChannelsAndOauthTokens do
  use Ecto.Migration

  alias Ask.Repo

  defmodule Channel do
    use Ask.Web, :model

    schema "channels" do
      field :provider, :string
      field :base_url, :string

      Ecto.Schema.timestamps()
    end

    def changeset(struct, params \\ %{}) do
      struct |> cast(params, [:provider, :base_url])
    end
  end

  defmodule OAuthToken do
    use Ask.Web, :model

    schema "oauth_tokens" do
      field :provider, :string
      field :base_url, :string

      Ecto.Schema.timestamps()
    end

    def changeset(struct, params \\ %{}) do
      struct |> cast(params, [:provider, :base_url])
    end
  end

  def up do
    Channel
    |> Repo.all
    |> Enum.each(fn channel ->
      base_url = fetch_base_url(channel.provider)
      channel |> Channel.changeset(%{base_url: base_url}) |> Repo.update!
    end)

    OAuthToken
    |> Repo.all
    |> Enum.each(fn channel ->
      base_url = fetch_base_url(channel.provider)
      channel |> Channel.changeset(%{base_url: base_url}) |> Repo.update!
    end)
  end

  def down do
  end

  defp fetch_base_url("nuntium") do
    fetch_base_url Application.get_env(:ask, Nuntium)
  end

  defp fetch_base_url("verboice") do
    fetch_base_url Application.get_env(:ask, Verboice)
  end

  defp fetch_base_url(config) do
    if Keyword.keyword?(config) do
      config[:base_url]
    else
      fetch_base_url(hd(config))
    end
  end
end
