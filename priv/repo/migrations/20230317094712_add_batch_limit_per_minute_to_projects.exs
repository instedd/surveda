defmodule Ask.Repo.Migrations.AddBatchLimitPerMinuteToProjects do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      add :batch_limit_per_minute, :integer
    end
  end
end
