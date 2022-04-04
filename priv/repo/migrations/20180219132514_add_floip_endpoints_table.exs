defmodule Ask.Repo.Migrations.AddFloipEndpointsTable do
  use Ecto.Migration

  def change do
    create table(:floip_endpoints, primary_key: false) do
      add :survey_id, references(:surveys, on_delete: :delete_all), primary_key: true
      add :uri, :string, primary_key: true
      add :last_pushed_response_id, references(:responses, on_delete: :nothing)
      add :retries, :integer, default: 0
      add :name, :string

      timestamps()
    end

    create index(:surveys, [:id])
  end
end
