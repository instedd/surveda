defmodule Ask.Repo.Migrations.ModifyRespondentGroupSampleToLongText do
  use Ecto.Migration

  def up do
    alter table(:respondent_groups) do
      modify :sample, :longtext
    end
  end

  def down do
    alter table(:respondent_groups) do
      modify :sample, :string
    end
  end
end
