defmodule Ask.Repo.Migrations.CreateProjectChannels do
  use Ecto.Migration

  def change do
    create table(:project_channels) do
      add :channel_id, references(:channels, on_delete: :delete_all)
      add :project_id, references(:projects, on_delete: :delete_all)

      timestamps()
    end

    create unique_index(:project_channels, [:channel_id, :project_id])
  end
end
