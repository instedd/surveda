defmodule AskWeb.DayOfWeekTest do
  use Ask.DataCase
  alias Ask.DayOfWeek

  test "every_day" do
    assert %DayOfWeek{sun: true, mon: true, tue: true, wed: true, thu: true, fri: true, sat: true} =
             DayOfWeek.every_day()
  end

  describe "dump:" do
    test "should dump Saturday" do
      assert {:ok, ["sat"]} = DayOfWeek.dump(%DayOfWeek{sat: true})
    end

    test "should dump Friday" do
      assert {:ok, ["fri"]} = DayOfWeek.dump(%DayOfWeek{fri: true})
    end

    test "should dump Thursday" do
      assert {:ok, ["thu"]} = DayOfWeek.dump(%DayOfWeek{thu: true})
    end

    test "should dump Wednesday" do
      assert {:ok, ["wed"]} = DayOfWeek.dump(%DayOfWeek{wed: true})
    end

    test "should dump Tuesday" do
      assert {:ok, ["tue"]} = DayOfWeek.dump(%DayOfWeek{tue: true})
    end

    test "should dump Monday" do
      assert {:ok, ["mon"]} = DayOfWeek.dump(%DayOfWeek{mon: true})
    end

    test "should dump Sunday" do
      assert {:ok, ["sun"]} = DayOfWeek.dump(%DayOfWeek{sun: true})
    end

    test "should dump Thursday and Saturday" do
      assert {:ok, ["thu", "sat"]} = DayOfWeek.dump(%DayOfWeek{thu: true, sat: true})
    end

    test "should dump weekdays" do
      assert {:ok, ["mon", "tue", "wed", "thu", "fri"]} =
               DayOfWeek.dump(%DayOfWeek{mon: true, tue: true, wed: true, thu: true, fri: true})
    end

    test "should dump Sunday and Saturday" do
      assert {:ok, ["sun", "sat"]} = DayOfWeek.dump(%DayOfWeek{sun: true, sat: true})
    end
  end

  describe "load:" do
    test "should load Saturday" do
      assert {:ok, %DayOfWeek{sat: true}} = DayOfWeek.load(["sat"])
    end

    test "should load Friday" do
      assert {:ok, %DayOfWeek{fri: true}} = DayOfWeek.load(["fri"])
    end

    test "should load Thursday" do
      assert {:ok, %DayOfWeek{thu: true}} = DayOfWeek.load(["thu"])
    end

    test "should load Wednesday" do
      assert {:ok, %DayOfWeek{wed: true}} = DayOfWeek.load(["wed"])
    end

    test "should load Tuesday" do
      assert {:ok, %DayOfWeek{tue: true}} = DayOfWeek.load(["tue"])
    end

    test "should load Monday" do
      assert {:ok, %DayOfWeek{mon: true}} = DayOfWeek.load(["mon"])
    end

    test "should load Sunday" do
      assert {:ok, %DayOfWeek{sun: true}} = DayOfWeek.load(["sun"])
    end

    test "should load Thursday and Saturday" do
      assert {:ok, %DayOfWeek{thu: true, sat: true}} = DayOfWeek.load(["thu", "sat"])
    end

    test "should load weekdays" do
      assert {:ok, %DayOfWeek{mon: true, tue: true, wed: true, thu: true, fri: true}} =
               DayOfWeek.load(["mon", "tue", "wed", "thu", "fri"])
    end

    test "should load Sunday and Saturday" do
      assert {:ok, %DayOfWeek{sun: true, sat: true}} = DayOfWeek.load(["sun", "sat"])
    end

    test "should load every day" do
      assert {:ok,
              %DayOfWeek{
                sun: true,
                mon: true,
                tue: true,
                wed: true,
                thu: true,
                fri: true,
                sat: true
              }} = DayOfWeek.load(["sun", "mon", "tue", "wed", "thu", "fri", "sat"])
    end
  end

  describe "cast:" do
    test "shuld cast to itself" do
      assert {:ok, %DayOfWeek{sun: true, sat: true}} =
               DayOfWeek.cast(%DayOfWeek{sun: true, sat: true})
    end

    test "shuld cast a struct with string keys" do
      assert {
               :ok,
               %DayOfWeek{
                 sun: true,
                 mon: true,
                 tue: true,
                 wed: true,
                 thu: true,
                 fri: false,
                 sat: true
               }
             } =
               DayOfWeek.cast(%{
                 "sun" => true,
                 "mon" => true,
                 "tue" => true,
                 "wed" => true,
                 "thu" => true,
                 "fri" => false,
                 "sat" => true
               })
    end

    test "shuld cast an array of days" do
      assert {
               :ok,
               %DayOfWeek{
                 sun: true,
                 mon: true,
                 tue: true,
                 wed: true,
                 thu: true,
                 fri: false,
                 sat: true
               }
             } = DayOfWeek.cast(["sun", "mon", "tue", "wed", "thu", "sat"])
    end

    test "shuld cast nil" do
      assert {:ok,
              %DayOfWeek{sun: nil, mon: nil, tue: nil, wed: nil, thu: nil, fri: nil, sat: nil}} =
               DayOfWeek.cast(nil)
    end
  end

  describe "operations:" do
    test "should detect intersections" do
      assert Ask.DayOfWeek.intersect?(%DayOfWeek{sun: true, mon: true}, %DayOfWeek{
               mon: true,
               tue: true
             })

      refute Ask.DayOfWeek.intersect?(%DayOfWeek{sun: true, fri: true}, %DayOfWeek{
               mon: true,
               tue: true
             })
    end
  end
end
