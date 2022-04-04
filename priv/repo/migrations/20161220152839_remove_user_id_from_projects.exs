defmodule Ask.Repo.Migrations.RemoveUserIdFromProjects do
  use Ecto.Migration

  def change do
    Ask.Repo.transaction(fn ->
      Ask.Repo.query!("ALTER TABLE projects DROP FOREIGN KEY projects_user_id_fkey")

      alter table(:projects) do
        remove :user_id
      end
    end)
  end
end
