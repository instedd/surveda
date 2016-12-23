defmodule Ask.Repo.Migrations.AddErrorMsgToQuesionnaires do
  use Ecto.Migration

  def change do
    alter table(:questionnaires) do
      add :error_msg, :text
    end
  end
end
