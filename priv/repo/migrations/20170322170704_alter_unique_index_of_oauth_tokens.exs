defmodule Ask.Repo.Migrations.AlterUniqueIndexOfOauthTokens do
  use Ecto.Migration

  def up do
    Ask.Repo.query("alter table oauth_tokens drop foreign key oauth_tokens_user_id_fkey")
    drop unique_index(:oauth_tokens, [:user_id, :provider])
    create unique_index(:oauth_tokens, [:user_id, :provider, :base_url])
  end

  def down do
    drop unique_index(:oauth_tokens, [:user_id, :provider, :base_url])
    create unique_index(:oauth_tokens, [:user_id, :provider])
  end
end
