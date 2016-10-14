defmodule Ask.Repo.Migrations.ChangeSurveyScheduleStartAndEndToTime do
  use Ecto.Migration

  def change do
    alter table(:surveys) do
      modify :schedule_start_time, :time
      modify :schedule_end_time, :time
    end
  end
end
