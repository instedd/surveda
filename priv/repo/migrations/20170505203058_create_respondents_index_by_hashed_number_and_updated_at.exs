defmodule Ask.Repo.Migrations.CreateRespondentsIndexByHashedNumberAndUpdatedAt do
  use Ecto.Migration

  def change do
    create index(:respondents, [:hashed_number])
    create index(:respondents, [:updated_at])
  end
end
