defmodule Ask.DayOfWeekTest do
  use Ask.ModelCase
  alias Ask.DayOfWeek

  describe "dump:" do
    test "should dump 1 for Saturday" do
      assert {:ok, 1} = DayOfWeek.dump(%DayOfWeek{sat: true})
    end

    test "should dump 2 for Friday" do
      assert {:ok, 2} = DayOfWeek.dump(%DayOfWeek{fri: true})
    end

    test "should dump 4 for Thursday" do
      assert {:ok, 4} = DayOfWeek.dump(%DayOfWeek{thu: true})
    end

    test "should dump 8 for Wednesday" do
      assert {:ok, 8} = DayOfWeek.dump(%DayOfWeek{wed: true})
    end

    test "should dump 16 for Tuesday" do
      assert {:ok, 16} = DayOfWeek.dump(%DayOfWeek{tue: true})
    end

    test "should dump 32 for Monday" do
      assert {:ok, 32} = DayOfWeek.dump(%DayOfWeek{mon: true})
    end

    test "should dump 64 for Sunday" do
      assert {:ok, 64} = DayOfWeek.dump(%DayOfWeek{sun: true})
    end

    test "should dump 5 for Thursday and Saturday" do
      assert {:ok, 5} = DayOfWeek.dump(%DayOfWeek{thu: true, sat: true})
    end

    test "should dump 62 for weekdays" do
      assert {:ok, 62} = DayOfWeek.dump(%DayOfWeek{mon: true, tue: true, wed: true, thu: true, fri: true})
    end

    test "should dump 65 for Thursday and Saturday" do
      assert {:ok, 65} = DayOfWeek.dump(%DayOfWeek{sun: true, sat: true})
    end
  end

  describe "load:" do
    test "should load 1 as Saturday" do
      assert {:ok, %DayOfWeek{sat: true}} = DayOfWeek.load(1)
    end

    test "should load 2 as Friday" do
      assert {:ok, %DayOfWeek{fri: true}} = DayOfWeek.load(2)
    end

    test "should load 4 as Thursday" do
      assert {:ok, %DayOfWeek{thu: true}} = DayOfWeek.load(4)
    end

    test "should load 8 as Wednesday" do
      assert {:ok, %DayOfWeek{wed: true}} = DayOfWeek.load(8)
    end

    test "should load 16 as Tuesday" do
      assert {:ok, %DayOfWeek{tue: true}} = DayOfWeek.load(16)
    end

    test "should load 32 as Monday" do
      assert {:ok, %DayOfWeek{mon: true}} = DayOfWeek.load(32)
    end

    test "should load 64 as Sunday" do
      assert {:ok, %DayOfWeek{sun: true}} = DayOfWeek.load(64)
    end

    test "should load 5 as Thursday and Saturday" do
      assert {:ok, %DayOfWeek{thu: true, sat: true}} = DayOfWeek.load(5)
    end

    test "should load 62 as weekdays" do
      assert {:ok, %DayOfWeek{mon: true, tue: true, wed: true, thu: true, fri: true}} = DayOfWeek.load(62)
    end

    test "should load 65 as Sunday and Saturday" do
      assert {:ok, %DayOfWeek{sun: true, sat: true}} = DayOfWeek.load(65)
    end

    test "should load 127 as every day" do
      assert {:ok, %DayOfWeek{sun: true, mon: true, tue: true, wed: true, thu: true, fri: true, sat: true}} = DayOfWeek.load(127)
    end

    test "should fail when trying to load an integer bigger than 127" do
      assert :error = DayOfWeek.load(128)
    end
  end

  describe "cast:" do
    test "shuld cast to itself" do
      assert {:ok, %DayOfWeek{sun: true, sat: true}} = DayOfWeek.cast(%DayOfWeek{sun: true, sat: true})
    end

    test "shuld cast a struct with string keys" do
      assert {
        :ok,
        %DayOfWeek{sun: true, mon: true, tue: true, wed: true, thu: true, fri: false, sat: true}
      } = DayOfWeek.cast(%{"sun" => true, "mon" => true, "tue" => true, "wed" => true, "thu" => true, "fri" => false, "sat" => true})
    end

    test "shuld cast an integer if it's smaller than 127" do
      assert {:ok, %DayOfWeek{sun: true, mon: true, tue: true, wed: true, thu: true, fri: true, sat: true}} = DayOfWeek.cast(127)
    end

    test "shuld error if the integer is bigger than 127" do
      assert :error = DayOfWeek.cast(128)
    end

    test "shuld cast nil" do
      assert {:ok, %DayOfWeek{sun: nil, mon: nil, tue: nil, wed: nil, thu: nil, fri: nil, sat: nil}} = DayOfWeek.cast(nil)
    end
  end
end
