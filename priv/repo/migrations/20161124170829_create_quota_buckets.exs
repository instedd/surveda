defmodule Ask.Repo.Migrations.CreateQuotaBuckets do
  use Ecto.Migration

  def change do
    create table(:quota_buckets) do
      add :condition, :text
      add :quota, :integer
      add :count, :integer
      add :survey_id, references(:surveys, on_delete: :delete_all, on_update: :update_all)

      timestamps()
    end
  end
end
