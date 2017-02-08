defmodule Ask.Repo.Migrations.AddUniqueIndexToInvites do
  use Ecto.Migration

  def up do
    Ask.Repo.query!("CREATE TABLE tmp LIKE invites")
    Ask.Repo.query!("ALTER TABLE tmp ADD UNIQUE INDEX(project_id, email)")
    Ask.Repo.query!("INSERT INTO tmp SELECT * FROM invites
        ON DUPLICATE KEY UPDATE tmp.id=invites.id")
    Ask.Repo.query!("RENAME TABLE invites to deleteme, tmp to invites")
    Ask.Repo.query!("DROP TABLE deleteme")
  end

  def down do
    Ask.Repo.query!("ALTER TABLE invites DROP INDEX project_id")
  end

end
