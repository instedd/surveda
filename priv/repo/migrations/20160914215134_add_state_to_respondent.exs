defmodule Ask.Repo.Migrations.AddStateToRespondent do
  use Ecto.Migration

  def change do
    alter table(:respondents) do
      add :state, :string, default: "pending"
    end
  end
end
