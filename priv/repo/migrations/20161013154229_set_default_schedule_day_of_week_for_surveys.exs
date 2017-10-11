defmodule Ask.Repo.Migrations.SetDefaultScheduleDayOfWeekForSurveys do
  use Ecto.Migration
  import Ecto.Query

  defmodule Survey do
    use Ask.Web, :model

    schema "surveys" do
      field :schedule_day_of_week, :integer
    end

    def changeset(struct, params \\ %{}) do
      struct
      |> cast(params, [:schedule_day_of_week])
    end
  end

  def change do
    from(s in Ask.Survey, where: is_nil(s.schedule_day_of_week))
    |> Ask.Repo.update_all(set: [schedule_day_of_week: 127]) # 127 was every_day in the old ecto type
  end
end
