defmodule Ask.Repo.Migrations.AddSanitizedPhoneNumberToRespondent do
  use Ecto.Migration

  def change do
    alter table(:respondents) do
      add :sanitized_phone_number, :string
    end
  end
end
