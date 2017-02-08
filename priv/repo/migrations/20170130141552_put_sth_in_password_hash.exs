defmodule Ask.Repo.Migrations.PutSthInPasswordHash do
  use Ecto.Migration

  def change do
    Ask.Repo.query!("UPDATE users SET password_hash='1' WHERE password_hash IS NULL")
  end
end
