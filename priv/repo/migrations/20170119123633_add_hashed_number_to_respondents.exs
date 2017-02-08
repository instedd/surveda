defmodule Ask.Repo.Migrations.AddHashedNumberToRespondents do
  use Ecto.Migration

  def up do
    alter table(:respondents) do
      add :hashed_number, :string
    end
  end

  def down do
    alter table(:respondents) do
      remove :hashed_number
    end
  end

end
