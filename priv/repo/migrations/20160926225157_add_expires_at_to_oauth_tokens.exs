defmodule Ask.Repo.Migrations.AddExpiresAtToOauthTokens do
  use Ecto.Migration

  def change do
    alter table(:oauth_tokens) do
      add :expires_at, :datetime
    end
  end
end
