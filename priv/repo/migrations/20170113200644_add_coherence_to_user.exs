defmodule Ask.Repo.Migrations.AddCoherenceToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      # authenticatable
      add :password_hash, :string
      # recoverable
      add :reset_password_token, :string
      add :reset_password_sent_at, :naive_datetime
      # confirmable
      add :confirmation_token, :string
      add :confirmed_at, :naive_datetime
      add :confirmation_sent_at, :naive_datetime
    end
  end
end
