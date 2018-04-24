defmodule Ask.Repo.Migrations.AddStateToFloipEndpointTable do
  use Ecto.Migration

  def change do
    alter table(:floip_endpoints) do
      add :state, :string
    end
  end
end
