defmodule Ask.Repo.Migrations.AddIvrActiveToRetryStats do
  use Ecto.Migration

  def up do
    alter table(:retry_stats) do
      add(:ivr_active, :boolean, null: true)
      modify(:retry_time, :string, null: true)
    end

    execute "UPDATE retry_stats SET ivr_active = true, retry_time = null WHERE retry_time = ''"
    execute "UPDATE retry_stats SET ivr_active = false WHERE retry_time <> ''"

    alter table(:retry_stats) do
      modify(:ivr_active, :boolean, null: false)
    end
  end

  def down do
    execute "UPDATE retry_stats SET retry_time = '' WHERE ivr_active = true AND retry_time IS null"

    alter table(:retry_stats) do
      remove(:ivr_active)
    end
  end
end
