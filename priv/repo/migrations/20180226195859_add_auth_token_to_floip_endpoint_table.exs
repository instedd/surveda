defmodule Ask.Repo.Migrations.AddAuthTokenToFloipEndpointTable do
  use Ecto.Migration

  def change do
    alter table(:floip_endpoints) do
      add :auth_token, :string
    end
  end
end
