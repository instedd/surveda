defmodule Ask.Repo.Migrations.CreatePanelSurvey do
  use Ecto.Migration

  def change do
    create table(:panel_surveys) do
      add(:name, :string)
      add(:project_id, references(:projects))
      add(:folder_id, references(:folders))

      timestamps()
    end
  end
end
