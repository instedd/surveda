defmodule Ask.Repo.Migrations.AddRespondentGroupIdToRespondents do
  use Ecto.Migration

  def change do
    alter table(:respondents) do
      add :respondent_group_id, references(:respondent_groups)
    end
  end
end
