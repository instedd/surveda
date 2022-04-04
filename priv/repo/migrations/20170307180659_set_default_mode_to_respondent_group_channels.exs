defmodule Ask.Repo.Migrations.SetDefaultModeToRespondentGroupChannels do
  use Ecto.Migration
  alias Ask.Repo

  def up do
    Repo.query!("SELECT ch.id, ch.type
      FROM channels AS ch").rows
    |> Enum.each(fn [channel_id, channel_type] ->
      Repo.query!(
        "UPDATE respondent_group_channels
          SET mode = ?
          WHERE channel_id = ?",
        [channel_type, channel_id]
      )
    end)
  end

  def down do
  end
end
