defmodule Ask.Repo.Migrations.MigrateSurveySchedule do
  use Ecto.Migration
  alias Ask.Repo

  defmodule DayOfWeek do
    import Bitwise
    use Ecto.Type

    alias __MODULE__

    defstruct [:sun, :mon, :tue, :wed, :thu, :fri, :sat]

    @sun 64
    @mon 32
    @tue 16
    @wed 8
    @thu 4
    @fri 2
    @sat 1

    def type, do: :integer

    def cast(%{sun: sun, mon: mon, tue: tue, wed: wed, thu: thu, fri: fri, sat: sat}) do
      {:ok, %DayOfWeek{sun: sun, mon: mon, tue: tue, wed: wed, thu: thu, fri: fri, sat: sat}}
    end
    def cast(map = %{}) do
      {:ok, %DayOfWeek{sun: map["sun"], mon: map["mon"], tue: map["tue"], wed: map["wed"], thu: map["thu"], fri: map["fri"], sat: map["sat"]}}
    end
    def cast(%{sun: sun, mon: mon, tue: tue, wed: wed, thu: thu, fri: fri, sat: sat}) do
      {:ok, %DayOfWeek{sun: sun, mon: mon, tue: tue, wed: wed, thu: thu, fri: fri, sat: sat}}
    end
    def cast(int) when is_integer(int) and int < 128, do: load(int)
    def cast(nil), do: {:ok, %DayOfWeek{}}
    def cast(_), do: :error

    def load(int) when is_integer(int) and int < 128 do
      {
        :ok,
        %DayOfWeek{
          sun: (int &&& @sun) == @sun,
          mon: (int &&& @mon) == @mon,
          tue: (int &&& @tue) == @tue,
          wed: (int &&& @wed) == @wed,
          thu: (int &&& @thu) == @thu,
          fri: (int &&& @fri) == @fri,
          sat: (int &&& @sat) == @sat
        }
      }
    end
    def load(nil), do: {:ok, %DayOfWeek{}}
    def load(_), do: :error

    def dump(%{sun: sun, mon: mon, tue: tue, wed: wed, thu: thu, fri: fri, sat: sat}) do
      {
        :ok,
          (sun && @sun || 0) |||
          (mon && @mon || 0) |||
          (tue && @tue || 0) |||
          (wed && @wed || 0) |||
          (thu && @thu || 0) |||
          (fri && @fri || 0) |||
          (sat && @sat || 0)
      }
    end
    def dump(_), do: :error

    def never() do
      %DayOfWeek{}
    end
  end

  defmodule NewDayOfWeek do
    alias __MODULE__

    defstruct [:sun, :mon, :tue, :wed, :thu, :fri, :sat]

    def cast(%NewDayOfWeek{} = day_of_week) do
      {:ok, day_of_week}
    end
    def cast(%{sun: sun, mon: mon, tue: tue, wed: wed, thu: thu, fri: fri, sat: sat}) do
      {:ok, %NewDayOfWeek{sun: sun, mon: mon, tue: tue, wed: wed, thu: thu, fri: fri, sat: sat}}
    end
    def cast(map = %{}) do
      {:ok, %NewDayOfWeek{sun: map["sun"], mon: map["mon"], tue: map["tue"], wed: map["wed"], thu: map["thu"], fri: map["fri"], sat: map["sat"]}}
    end
    def cast(array) when is_list(array), do: load(array)
    def cast(nil), do: {:ok, %NewDayOfWeek{}}
    def cast(_), do: :error

    def load(array) when is_list(array) do
      day_of_week = array |> Enum.reduce(never(), fn(day, result) ->
        %NewDayOfWeek{
          sun: result.sun || day == "sun",
          mon: result.mon || day == "mon",
          tue: result.tue || day == "tue",
          wed: result.wed || day == "wed",
          thu: result.thu || day == "thu",
          fri: result.fri || day == "fri",
          sat: result.sat || day == "sat"
        }
      end)

      {:ok, day_of_week}
    end
    def load(nil), do: {:ok, %NewDayOfWeek{}}
    def load(_), do: :error

    def dump(%{} = day_of_week) do
      day_of_week = ~w(sun mon tue wed thu fri sat)
      |> Enum.filter(fn(day) ->
        Map.get(day_of_week, String.to_atom(day))
      end)

      {:ok, day_of_week}
    end
    def dump(_), do: :error

    def never() do
      %NewDayOfWeek{}
    end
  end

  defmodule Schedule do
    use Ecto.Type

    alias __MODULE__

    defstruct [:day_of_week, :start_time, :end_time, :blocked_days, :timezone]

    def type, do: :text

    def cast(%Schedule{} = schedule) do
      {:ok, schedule}
    end
    def cast(%{day_of_week: day_of_week, start_time: start_time, end_time: end_time, blocked_days: blocked_days, timezone: timezone}) do
      case NewDayOfWeek.cast(day_of_week) do
        :error -> :error
        {:ok, dow} ->
          {:ok, %Schedule{day_of_week: dow, start_time: start_time, end_time: end_time, blocked_days: blocked_days, timezone: timezone}}
      end
    end
    def cast(%{} = map) do
      case NewDayOfWeek.cast(map["day_of_week"]) do
        :error -> :error
        {:ok, dow} ->
          {:ok, %Schedule{day_of_week: dow, start_time: map["start_time"], end_time: map["end_time"], blocked_days: map["blocked_days"], timezone: map["timezone"]}}
      end
    end
    def cast(string) when is_binary(string), do: load(string)
    def cast(nil), do: {:ok, %Schedule{}}
    def cast(_), do: :error

    def load(string) when is_binary(string), do: cast(Poison.decode!(string))
    def load(nil), do: {:ok, %Schedule{}}
    def load(_), do: :error

    def dump(%Schedule{day_of_week: day_of_week}=schedule) do
      {:ok, day_of_week}= NewDayOfWeek.dump(day_of_week)
      schedule = %{schedule |
        day_of_week: day_of_week,
        blocked_days: schedule.blocked_days || []
      }
      Poison.encode(schedule)
    end
    def dump(_), do: :error

    def default() do
      %Schedule{
        day_of_week: NewDayOfWeek.never(),
        start_time: ~T[09:00:00],
        end_time: ~T[18:00:00],
        blocked_days: []
      }
    end
  end

  defmodule Survey do
    use Ask.Web, :model

    schema "surveys" do
      field :schedule_day_of_week, DayOfWeek, default: DayOfWeek.never()
      field :schedule_start_time, :time
      field :schedule_end_time, :time
      field :timezone, :string
      field :schedule, Schedule, default: Schedule.default()
    end

    def changeset(struct, params \\ %{}) do
      struct
      |> cast(params, [:schedule, :schedule_day_of_week, :schedule_start_time, :schedule_end_time, :timezone])
    end
  end

  def up do
    Survey |> Repo.all |> Enum.each(fn survey ->
      survey
      |> Survey.changeset(%{schedule: %Schedule{day_of_week: survey.schedule_day_of_week,
      start_time: survey.schedule_start_time, end_time: survey.schedule_end_time, timezone: survey.timezone}})
      |> Repo.update!
    end)
  end

  def down do
    Survey |> Repo.all |> Enum.each(fn survey ->
      survey
      |> Survey.changeset(%{schedule_day_of_week: survey.schedule.day_of_week,
      schedule_start_time: survey.schedule.start_time, schedule_end_time: survey.schedule.end_time, timezone: survey.schedule.timezone})
      |> Repo.update!
    end)
  end
end
