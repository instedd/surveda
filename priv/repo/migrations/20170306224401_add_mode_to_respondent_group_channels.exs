defmodule Ask.Repo.Migrations.AddModeToRespondentGroupChannels do
  use Ecto.Migration

  def change do
    alter table(:respondent_group_channels) do
      add :mode, :string
    end
  end
end
