defmodule Ask.Repo.Migrations.AddOnboardingToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :onboarding, :text
    end
  end
end
