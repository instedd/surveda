defmodule :"Elixir.Ask.Repo.Migrations.Add-user-stopped-to-respondents" do
  use Ecto.Migration

  def change do
    alter table(:respondents) do
      add :user_stopped, :boolean, default: false
    end
  end
end
