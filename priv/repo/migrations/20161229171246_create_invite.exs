defmodule Ask.Repo.Migrations.CreateInvite do
  use Ecto.Migration

  def change do
    create table(:invites) do
      add :code, :string
      add :level, :string
      add :project_id, references(:projects, on_delete: :delete_all)
      add :email, :string

      timestamps()
    end
  end
end
