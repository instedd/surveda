defmodule Ask.Repo.Migrations.AddPartialConfigToQuestionnaires do
  use Ecto.Migration

  def up do
    alter table(:questionnaires) do
      add :partial_config, :string
    end
  end

  def down do
    alter table(:questionnaires) do
      remove :partial_config
    end
  end
end
