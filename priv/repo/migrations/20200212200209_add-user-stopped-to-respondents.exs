defmodule :"Elixir.Ask.Repo.Migrations.Add-user-stopped-to-respondents" do
  use Ecto.Migration

  def up do
    alter table(:respondents), do: add(:user_stopped, :boolean, null: false, default: false)
    alter table(:respondents), do: modify(:user_stopped, :boolean, null: false)
  end

  def down do
    alter table(:respondents), do: remove(:user_stopped)
  end
end
