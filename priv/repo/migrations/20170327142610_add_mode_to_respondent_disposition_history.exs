defmodule Ask.Repo.Migrations.AddModeToRespondentDispositionHistory do
  use Ecto.Migration

  def change do
    alter table(:respondent_disposition_history) do
      add :mode, :string
    end
  end
end
