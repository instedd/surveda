defmodule Ask.Repo.Migrations.AddPartialRelevantConfigToQuestionnaires do
  use Ecto.Migration

  def up do
    alter table(:questionnaires) do
      add :partial_relevant_config, :string
    end
  end

  def down do
    alter table(:questionnaires) do
      remove :partial_relevant_config
    end
  end
end
