defmodule Ask.Runtime.SurveyCancellerSupervisorTest do
  use Ask.DataCase
  use Timex
  use Ask.MockTime
  use Ask.TestHelpers

  alias Ask.Repo
  alias Ask.Runtime.SurveyCancellerSupervisor

  describe "init" do
    test "supervisor doesn't init when no surveys are being cancelled" do
      {:ok, {_, processes}} = SurveyCancellerSupervisor.init([])
      assert [] = processes
    end

    test "supervisor starts when surveys to cancel" do
      build(:survey, state: :cancelling) |> Repo.insert!()
      {:ok, {_, processes}} = SurveyCancellerSupervisor.init([])
      assert Enum.count(processes) > 0
    end
  end
end
