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
    assert step == :end
  end

  test "first step" do
    step = Flow.start(@quiz) |> Flow.step()
    assert {:ok, %Flow{}, {:prompt, prompt}} = step
    assert prompt == hd(@quiz.steps)["title"]
  end

  test "last step" do
    flow = Flow.start(@quiz)
    {:ok, flow, _} = flow |> Flow.step()
    {:ok, flow, _} = flow |> Flow.step()
    step = flow |> Flow.step()
    assert step == :end
  end
end
