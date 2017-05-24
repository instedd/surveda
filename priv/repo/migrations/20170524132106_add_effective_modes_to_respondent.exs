defmodule Ask.Repo.Migrations.AddEffectiveModesToRespondent do
  use Ecto.Migration

  def change do
    alter table(:respondents) do
      add :effective_modes, :string
    end
  end
end
