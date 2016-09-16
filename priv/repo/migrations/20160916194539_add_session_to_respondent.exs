defmodule Ask.Repo.Migrations.AddSessionToRespondent do
  use Ecto.Migration

  def change do
    alter table(:respondents) do
      add :session, :text
    end
  end
end
