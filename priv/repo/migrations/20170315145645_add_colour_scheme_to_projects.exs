defmodule Ask.Repo.Migrations.AddColourSchemeToProjects do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      add :colour_scheme, :string, default: "default"
    end
  end
end
