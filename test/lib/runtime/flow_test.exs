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
    assert prompts == ["Do you smoke? Press 1 for YES, 2 for NO"]
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
    assert prompts == ["Do you exercise? Press 1 for YES, 2 for NO"]
  end

  test "next step with store, case insensitive, strip space" do
    {:ok, flow, _} = Flow.start(@quiz) |> Flow.step()
    step = flow |> Flow.step(" y ")
    assert {:ok, %Flow{}, %{stores: stores, prompts: prompts}} = step
    assert stores == %{"Smokes" => "Yes"}
    assert prompts == ["Do you exercise? Press 1 for YES, 2 for NO"]
  end

  test "last step" do
    flow = Flow.start(@quiz)
    {:ok, flow, _} = flow |> Flow.step()
    {:ok, flow, _} = flow |> Flow.step("Y")
    {:ok, flow, _} = flow |> Flow.step("N")
    step = flow |> Flow.step("99")
    assert {:end, _} = step
  end

  # skip logic
  test "when skip_logic is end it ends the flow" do
    quiz = build(:questionnaire, steps: @skip_logic)
    {:ok, flow, _} =
      quiz
      |> Flow.start
      |> Flow.step

    result =
      flow
      |> Flow.step("Y")

    assert {:end, _} = result
  end

  test "when skip_logic is null it continues with next step" do
    quiz = build(:questionnaire, steps: @skip_logic)
    {:ok, flow, _} =
      quiz
      |> Flow.start
      |> Flow.step

    result =
      flow
      |> Flow.step("N")

    assert {:ok, _, _} = result
  end

  test "when skip_logic is not present continues with next step" do
    quiz = build(:questionnaire, steps: @skip_logic)
    {:ok, flow, _} =
      quiz
      |> Flow.start
      |> Flow.step

    result =
      flow
      |> Flow.step("M")

    assert {:ok, _, _} = result
  end

  test "when skip_log is a valid id jumps to the specified id " do
    quiz = build(:questionnaire, steps: @skip_logic)
    {:ok, flow, _} =
      quiz
      |> Flow.start
      |> Flow.step

    {:ok, flow, _} =
      flow
      |> Flow.step("S")

    assert flow.current_step == 2
  end

  describe "when skip_log is an invalid id" do

    test "when it doesn't exist raises" do
      quiz = build(:questionnaire, steps: @skip_logic)
      {:ok, flow, _} =
        quiz
        |> Flow.start
        |> Flow.step

      assert_raise RuntimeError, fn ->
        flow
        |> Flow.step("A")
      end
    end

    test "when the step is previous raises" do
      quiz = build(:questionnaire, steps: @skip_logic)
      {:ok, flow, _} =
        quiz
        |> Flow.start
        |> Flow.step

      {:ok, flow, _} =
        flow
        |> Flow.step("M")

      assert_raise RuntimeError, fn ->
        flow
        |> Flow.step("Y")
      end
    end

  end

end
