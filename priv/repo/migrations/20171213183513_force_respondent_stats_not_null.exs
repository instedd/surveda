defmodule Ask.Repo.Migrations.ForceRespondentStatsNotNull do
  use Ecto.Migration

  def up do
    execute "UPDATE respondents SET stats = '{\"total_sent_sms\":0,\"total_received_sms\":0,\"total_call_time\":0,\"current_call_last_interaction_time\":null,\"current_call_first_interaction_time\":null}'"

    alter table(:respondents) do
      modify :stats, :longtext, null: false
    end
  end

  def down do
    alter table(:respondents) do
      modify :stats, :longtext, null: true
    end
  end
end
