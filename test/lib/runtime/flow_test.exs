defmodule Ask.FlowTest do
  use ExUnit.Case
  import Ask.Factory
  alias Ask.Runtime.Flow

  @quiz build(:questionnaire, steps: [%{prompt: %{text: "hi"}}])

  test "start" do
    session = Flow.start(@quiz)
    assert %Flow{} = session
  end

  test "first step of empty quiz" do
    quiz = build(:questionnaire)
    step = Flow.start(quiz) |> Flow.step()
    assert step == :end
  end

  test "first step" do
    step = Flow.start(@quiz) |> Flow.step()
    assert {:ok, %Flow{}, {:prompt, prompt}} = step
    assert prompt == hd(@quiz.steps).prompt
  end

  test "last step" do
    {:ok, session, _} = Flow.start(@quiz) |> Flow.step()
    step = session |> Flow.step()
    assert step == :end
  end
end
