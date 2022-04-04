defmodule Ask.Repo.Migrations.SetDefaultRespondentsCanonicalPhoneNumber do
  use Ecto.Migration

  def up do
    execute "UPDATE respondents SET canonical_phone_number = sanitized_phone_number"
  end

  def down do
    execute "UPDATE respondents SET canonical_phone_number = NULL"
  end
end
