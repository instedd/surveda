defmodule Ask.Repo.Migrations.AddSettingsToProjects do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      add :timezone, :string
      add :initial_success_rate, :float
      add :eligibility_rate, :float
      add :response_rate, :float
      add :valid_respondent_rate, :float
    end
  end
end
