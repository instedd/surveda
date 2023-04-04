defmodule Ask.Repo.Migrations.AddBatchSizeToProjects do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      add :batch_size, :integer
    end
  end
end
