defmodule Ask.Repo.Migrations.AddFloipEndpointsTable do
  use Ecto.Migration

  def change do
    drop table(:floip_endpoints)

    create table(:floip_endpoints) do
      add :survey_id, references(:surveys, on_delete: :delete_all)
      add :uri, :string
      add :last_pushed_response_id, references(:responses, on_delete: :nothing)
      add :retries, :integer, default: 0
      add :name, :string
      add :state, :string
      add :auth_token, :string

      timestamps()
    end

    create index(:floip_endpoints, [:survey_id, :uri, :auth_token], unique: true)
    create index(:floip_endpoints, [:survey_id])
  end
end
