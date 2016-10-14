defmodule Ask.DayOfWeek do
  @moduledoc """
  A custom type to map day of week schedules to the database, because
  MySQL doesn't support arrays.

  This type maps from a struct with a boolean per each day to a 7 bit binary
  that will have 0 or 1 on each position depending on whether the value was
  true or false for that particular day, starting on Sunday.

  Example:
  A working day schedule (mon - fri) will be stored as 62 ~> 0b0111110
  """

  import Bitwise
  @behaviour Ecto.Type

  defstruct [:sun, :mon, :tue, :wed, :thu, :fri, :sat]

  @sun 64
  @mon 32
  @tue 16
  @wed 8
  @thu 4
  @fri 2
  @sat 1

  def type, do: :integer

  def cast(%Ask.DayOfWeek{sun: sun, mon: mon, tue: tue, wed: wed, thu: thu, fri: fri, sat: sat}) do
    {:ok, %Ask.DayOfWeek{sun: sun, mon: mon, tue: tue, wed: wed, thu: thu, fri: fri, sat: sat}}
  end
  def cast(map = %{}) do
    {:ok, %Ask.DayOfWeek{sun: map["sun"], mon: map["mon"], tue: map["tue"], wed: map["wed"], thu: map["thu"], fri: map["fri"], sat: map["sat"]}}
  end
  def cast(%{sun: sun, mon: mon, tue: tue, wed: wed, thu: thu, fri: fri, sat: sat}) do
    {:ok, %Ask.DayOfWeek{sun: sun, mon: mon, tue: tue, wed: wed, thu: thu, fri: fri, sat: sat}}
  end
  def cast(int) when is_integer(int) and int < 128, do: load(int)
  def cast(nil), do: {:ok, %Ask.DayOfWeek{}}
  def cast(_), do: :error

  def load(int) when is_integer(int) and int < 128 do
    {
      :ok,
      %Ask.DayOfWeek{
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
  def load(nil), do: {:ok, %Ask.DayOfWeek{}}
  def load(_), do: :error

  def dump(%Ask.DayOfWeek{sun: sun, mon: mon, tue: tue, wed: wed, thu: thu, fri: fri, sat: sat}) do
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

  def every_day do
    %Ask.DayOfWeek{sun: true, mon: true, tue: true, wed: true, thu: true, fri: true, sat: true}
  end

  def never do
    %Ask.DayOfWeek{sun: false, mon: false, tue: false, wed: false, thu: false, fri: false, sat: false}
  end
end
