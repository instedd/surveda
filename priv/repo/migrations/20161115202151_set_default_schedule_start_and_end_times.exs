defmodule Ask.Repo.Migrations.SetDefaultScheduleStartAndEndTimes do
  use Ecto.Migration

  def change do
    Ask.Repo.query! "UPDATE surveys SET schedule_start_time = '09:00:00' WHERE schedule_start_time IS NULL"
    Ask.Repo.query! "UPDATE surveys SET schedule_end_time = '18:00:00' WHERE schedule_end_time IS NULL"
  end
end
