defmodule Ask.Repo.Migrations.AddSectionOrderToRespondent do
  use Ecto.Migration

  def change do
    alter table(:respondents) do
      add :section_order, :string
    end
  end
end
