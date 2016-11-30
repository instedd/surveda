defmodule Ask.Repo.Migrations.AddQuotaBucketIdToRespondent do
  use Ecto.Migration

  def change do
    alter table(:respondents) do
      add :quota_bucket_id, :integer
    end
  end
end
