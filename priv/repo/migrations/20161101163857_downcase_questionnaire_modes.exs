defmodule Ask.Repo.Migrations.DowncaseQuestionnaireModes do
  use Ecto.Migration

  def change do
    Ask.Repo.query!("update questionnaires set modes = lower(modes)")
  end
end
