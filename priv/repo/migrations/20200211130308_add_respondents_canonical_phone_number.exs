defmodule Ask.Repo.Migrations.AddRespondentsCanonicalPhoneNumber do
  use Ecto.Migration

  def change do
    alter table(:respondents) do
      add :canonical_phone_number, :string
    end
  end
end
