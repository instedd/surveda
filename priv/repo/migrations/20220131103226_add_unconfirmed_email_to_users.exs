defmodule Ask.Repo.Migrations.AddUnconfirmedEmailToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :unconfirmed_email, :string
    end
  end
end
