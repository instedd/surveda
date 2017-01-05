defmodule Ask.Repo.Migrations.AddInviterEmailToInvites do
  use Ecto.Migration

  def change do
    alter table(:invites) do
      add :inviter_email, :text
    end
  end
end
