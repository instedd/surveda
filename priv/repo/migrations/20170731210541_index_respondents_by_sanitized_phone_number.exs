defmodule Ask.Repo.Migrations.IndexRespondentsBySanitizedPhoneNumber do
  use Ecto.Migration

  def change do
    create index(:respondents, [:sanitized_phone_number])
  end
end
