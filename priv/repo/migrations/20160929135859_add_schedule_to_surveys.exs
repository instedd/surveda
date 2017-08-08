defmodule Ask.Repo.Migrations.AddScheduleToSurveys do
  use Ecto.Migration

  def change do
    alter table(:surveys) do
      add :schedule_day_of_week, :integer
      add :schedule_start_time, :datetime
      add :schedule_end_time, :datetime
    end
  end
end
