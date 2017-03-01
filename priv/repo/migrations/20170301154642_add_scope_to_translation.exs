defmodule Ask.Repo.Migrations.AddScopeToTranslation do
  use Ecto.Migration

  def change do
    alter table(:translations) do
      add :scope, :string
    end
  end
end
