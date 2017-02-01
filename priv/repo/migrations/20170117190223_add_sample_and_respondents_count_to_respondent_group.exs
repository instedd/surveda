defmodule Ask.Repo.Migrations.AddSampleAndRespondentsCountToRespondentGroup do
  use Ecto.Migration

  def change do
    alter table(:respondent_groups) do
      add :sample, :string
      add :respondents_count, :integer
    end
  end
end
