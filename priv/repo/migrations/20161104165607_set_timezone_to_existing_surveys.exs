defmodule Ask.Repo.Migrations.SetTimezoneToExistingSurveys do
  use Ecto.Migration

  def change do
    Ask.Repo.query! "update surveys set timezone = 'Etc/UTC'"
  end
end
