defmodule Ask.Repo.Migrations.SetDefaultScheduleDayOfWeekForSurveys do
  use Ecto.Migration
  import Ecto.Query

  def change do
    from(s in Ask.Survey, where: is_nil(s.schedule_day_of_week))
    |> Ask.Repo.update_all(set: [schedule_day_of_week: Ask.DayOfWeek.every_day])
  end
end
