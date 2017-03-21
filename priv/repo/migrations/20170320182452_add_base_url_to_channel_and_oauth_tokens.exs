defmodule Ask.Repo.Migrations.AddFriendlyNameToChannelAndOauthTokens do
  use Ecto.Migration

  def change do
    alter table(:channels) do
      add :base_url, :string
    end
    alter table(:oauth_tokens) do
      add :base_url, :string
    end
  end
end
