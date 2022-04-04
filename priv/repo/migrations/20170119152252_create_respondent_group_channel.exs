defmodule Ask.Repo.Migrations.CreateRespondentGroupChannel do
  use Ecto.Migration

  def change do
    create table(:respondent_group_channels) do
      add :respondent_group_id, references(:respondent_groups, on_delete: :nothing)
      add :channel_id, references(:channels, on_delete: :nothing)

      timestamps()
    end

    create index(:respondent_group_channels, [:respondent_group_id])
    create index(:respondent_group_channels, [:channel_id])
  end
end
