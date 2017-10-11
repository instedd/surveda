defmodule Ask.Repo.Migrations.RemoveSurveyDayOfWeekStartTimeAndEndTime do
  use Ecto.Migration

  def up do
    alter table(:surveys) do
      remove :schedule_day_of_week
      remove :schedule_start_time
      remove :schedule_end_time
      remove :timezone
    end
  end

  def down do
    alter table(:surveys) do
      add :schedule_day_of_week, :integer
      add :schedule_start_time, :time
      add :schedule_end_time, :time
      add :timezone, :string
    end
  end
end
