defmodule Ask.FlowTest do
  use ExUnit.Case
  use Ask.DummySteps
  import Ask.Factory
  alias Ask.Runtime.Flow

  @quiz build(:questionnaire, steps: @dummy_steps)

  test "start" do
    flow = Flow.start(@quiz)
    assert %Flow{} = flow
  end

  test "first step of empty quiz" do
    quiz = build(:questionnaire)
    step = Flow.start(quiz) |> Flow.step()
    assert {:end, _} = step
  end

  test "first step" do
    step = Flow.start(@quiz) |> Flow.step()
    assert {:ok, %Flow{}, %{prompts: prompts}} = step
    assert prompts == ["Do you smoke?"]
  end

  test "fail if a response is given to a flow that was never executed" do
    assert_raise RuntimeError, ~r/Flow was not expecting any reply/, fn ->
      Flow.start(@quiz) |> Flow.step("Y")
    end
  end

  test "next step with store" do
    {:ok, flow, _} = Flow.start(@quiz) |> Flow.step()
    step = flow |> Flow.step("Y")
    assert {:ok, %Flow{}, %{stores: stores, prompts: prompts}} = step
    assert stores == %{"Smokes" => "Yes"}
    assert prompts == ["Do you exercise?"]
  end

  test "next step with store, case insensitive, strip space" do
    {:ok, flow, _} = Flow.start(@quiz) |> Flow.step()
    step = flow |> Flow.step(" y ")
    assert {:ok, %Flow{}, %{stores: stores, prompts: prompts}} = step
    assert stores == %{"Smokes" => "Yes"}
    assert prompts == ["Do you exercise?"]
  end

  test "last step" do
    flow = Flow.start(@quiz)
    {:ok, flow, _} = flow |> Flow.step()
    {:ok, flow, _} = flow |> Flow.step("Y")
    {:ok, flow, _} = flow |> Flow.step("N")
    step = flow |> Flow.step("99")
    assert {:end, _} = step
  end
end
