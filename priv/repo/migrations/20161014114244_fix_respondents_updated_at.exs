defmodule Ask.Repo.Migrations.FixRespondentsUpdatedAt do
  use Ecto.Migration

  def change do
    Ask.Repo.query "update respondents set completed_at = updated_at where complete_at is null and state = 'completed'"
  end
end
