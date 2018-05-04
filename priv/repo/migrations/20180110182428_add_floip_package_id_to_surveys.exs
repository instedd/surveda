defmodule Ask.Repo.Migrations.AddFloipPackageIdToSurveys do
  use Ecto.Migration

  def change do
    alter table(:surveys) do
      add :floip_package_id, :string
    end

    execute "UPDATE surveys SET floip_package_id = UUID();"
  end
end
