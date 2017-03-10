defmodule Ask.Repo.Migrations.AddLockVersionToRespondents do
  use Ecto.Migration

  def change do
    alter table(:respondents) do
      add :lock_version, :integer, default: 1
    end
  end
end
