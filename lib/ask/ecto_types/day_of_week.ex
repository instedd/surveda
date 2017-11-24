defmodule Ask.DayOfWeek do
  alias __MODULE__

  defstruct [:sun, :mon, :tue, :wed, :thu, :fri, :sat]

  def cast(%DayOfWeek{} = day_of_week) do
    {:ok, day_of_week}
  end
  def cast(%{sun: sun, mon: mon, tue: tue, wed: wed, thu: thu, fri: fri, sat: sat}) do
    {:ok, %DayOfWeek{sun: sun, mon: mon, tue: tue, wed: wed, thu: thu, fri: fri, sat: sat}}
  end
  def cast(%{} = map) do
    {:ok, %DayOfWeek{sun: map["sun"], mon: map["mon"], tue: map["tue"], wed: map["wed"], thu: map["thu"], fri: map["fri"], sat: map["sat"]}}
  end
  def cast(array) when is_list(array), do: load(array)
  def cast(nil), do: {:ok, %DayOfWeek{}}
  def cast(_), do: :error

  def load(array) when is_list(array) do
    day_of_week = array |> Enum.reduce(never(), fn(day, result) ->
      %DayOfWeek{
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
  def load(nil), do: {:ok, %DayOfWeek{}}
  def load(_), do: :error

  def dump(%DayOfWeek{} = day_of_week) do
    day_of_week = ~w(sun mon tue wed thu fri sat)
    |> Enum.filter(fn(day) ->
      Map.get(day_of_week, String.to_atom(day))
    end)

    {:ok, day_of_week}
  end
  def dump(_), do: :error

  def dump!(day_of_week) do
    case dump(day_of_week) do
      {:ok, day_of_week} ->
        day_of_week
      :error ->
        raise "error when dumping #{day_of_week}"
    end
  end

  def intersect?(%DayOfWeek{} = days, %DateTime{} = date) do
    intersect?(days, from(date))
  end

  def intersect?(%DayOfWeek{} = days, %DayOfWeek{} = other) do
    {:ok, days} = dump(days)
    {:ok, other} = dump(other)
    !Enum.empty?(days -- (days -- other))
  end

  def every_day() do
    %DayOfWeek{sun: true, mon: true, tue: true, wed: true, thu: true, fri: true, sat: true}
  end

  def never() do
    %DayOfWeek{}
  end

  def from(%DateTime{} = date_time) do
    day_of_week = Date.day_of_week(date_time)
    %DayOfWeek{
      mon: day_of_week == 1,
      tue: day_of_week == 2,
      wed: day_of_week == 3,
      thu: day_of_week == 4,
      fri: day_of_week == 5,
      sat: day_of_week == 6,
      sun: day_of_week == 7,
    }
  end

  def any_day_selected?(%DayOfWeek{} = day_of_week) do
    !Enum.empty?(dump!(day_of_week))
  end
end
