defmodule Ask.Repo.Migrations.AddRememberCreatedAtToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :remember_created_at, :naive_datetime
    end
  end

end
