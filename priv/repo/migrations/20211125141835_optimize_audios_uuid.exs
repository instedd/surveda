# Use 36 bytes of fixed storage for storing UUIDs instead of a dynamically
# allocated storage of `1 + 36 * 3` bytes (109 bytes) with UTF8, without
# changing the actual UUID format.
defmodule Ask.Repo.Migrations.OptimizeAudiosUuid do
  use Ecto.Migration

  def up do
    execute "ALTER TABLE audios MODIFY uuid CHAR(36) CHARACTER SET ascii"
    create index(:audios, :uuid)
  end

  def down do
    execute "ALTER TABLE audios MODIFY uuid VARCHAR(255) CHARACTER SET utf8"
    drop index(:audios, :uuid)
  end
end
