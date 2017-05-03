defmodule Ask.Repo.Migrations.AddSnapshotOfToQuestionnaires do
  use Ecto.Migration

  def change do
    alter table(:questionnaires) do
      add :snapshot_of, references(:questionnaires, on_delete: :nothing)
    end
  end
end
