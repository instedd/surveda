defmodule Ask.Repo.Migrations.AddDispositionToRespondents do
  use Ecto.Migration

  def up do
    alter table(:respondents) do
      add :disposition, :string
    end
  end

  def down do
    alter table(:respondents) do
      remove :disposition
    end
  end

end
