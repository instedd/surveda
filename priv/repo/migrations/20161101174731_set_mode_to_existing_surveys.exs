defmodule Ask.Repo.Migrations.SetModeToExistingSurveys do
  use Ecto.Migration

  def change do
    Ask.Repo.query!("update surveys set mode = '[\"sms\"]'")
  end
end
