defmodule Ask.Repo.Migrations.AddIndexToRespondentsCanonicalPhoneNumbers do
  use Ecto.Migration

  def up do
    create index(:respondents, :canonical_phone_number)
  end

  def down do
    drop index(:respondents, :canonical_phone_number)
  end
end
