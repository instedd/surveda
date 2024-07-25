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

    test "supervisor starts canceller process for single survey to cancel" do
      %{id: survey_id} = build(:survey, state: :cancelling) |> Repo.insert!()
      {:ok, {_, processes}} = SurveyCancellerSupervisor.init([])
      assert Enum.count(processes) == 1
      %{ id: canceller_id } = processes |> hd
      assert survey_canceller_name(survey_id) == canceller_id
    end

    test "supervisor starts canceller process for multilpe surveys to cancel" do
      %{id: survey_id_1} = build(:survey, state: :cancelling) |> Repo.insert!()
      %{id: survey_id_2} = build(:survey, state: :cancelling) |> Repo.insert!()
      {:ok, {_, processes}} = SurveyCancellerSupervisor.init([])
      assert Enum.count(processes) == 2
      canceller_ids = Enum.map(processes, fn %{ id: canceller_id } -> canceller_id end) |> MapSet.new
      expected_ids = [ survey_canceller_name(survey_id_1), survey_canceller_name(survey_id_2) ] |> MapSet.new
      assert canceller_ids == expected_ids
    end
  end

  defp survey_canceller_name(survey_id), do: :"SurveyCanceller_#{survey_id}"
end
