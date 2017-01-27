defmodule Ask.Repo.Migrations.ConfirmAllUsers do
  use Ecto.Migration

  def change do
    Ask.Repo.query!("UPDATE users SET confirmed_at=NOW()")
  end
end
