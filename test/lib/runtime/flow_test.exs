defmodule Ask.FlowTest do
  use ExUnit.Case
  use Ask.DummySteps
  import Ask.Factory
  alias Ask.Runtime.Flow

  @quiz build(:questionnaire, steps: @dummy_steps)

  test "start" do
    flow = Flow.start(@quiz, "sms")
    assert %Flow{} = flow
  end

  test "first step of empty quiz" do
    quiz = build(:questionnaire)
    step = Flow.start(quiz, "sms") |> Flow.step()
    assert {:end, _} = step
  end

  test "first step (sms mode)" do
    step = Flow.start(@quiz, "sms") |> Flow.step()
    assert {:ok, %Flow{}, %{prompts: prompts}} = step
    assert prompts == ["Do you smoke? Reply 1 for YES, 2 for NO"]
  end

  test "first step (ivr mode)" do
    step = Flow.start(@quiz, "ivr") |> Flow.step()
    assert {:ok, %Flow{}, %{prompts: prompts}} = step
    assert prompts == [%{"text" => "Do you smoke? Press 8 for YES, 9 for NO", "audio_source" => "tts"}]
  end

  test "retry step" do
    {:ok, flow, _prompts} = Flow.start(@quiz, "sms") |> Flow.step
    {:ok, %Flow{}, %{prompts: prompts}} = flow |> Flow.retry
    assert prompts == ["Do you smoke? Reply 1 for YES, 2 for NO"]
  end

  test "fail if a response is given to a flow that was never executed" do
    assert_raise RuntimeError, ~r/Flow was not expecting any reply/, fn ->
      Flow.start(@quiz, "sms") |> Flow.step(Flow.Message.reply("Y"))
    end
  end

  test "next step with store" do
    {:ok, flow, _} = Flow.start(@quiz, "sms") |> Flow.step()
    step = flow |> Flow.step(Flow.Message.reply("Y"))
    assert {:ok, %Flow{}, %{stores: stores, prompts: prompts}} = step
    assert stores == %{"Smokes" => "Yes"}
    assert prompts == ["Do you exercise? Reply 1 for YES, 2 for NO"]
  end

  test "next step (ivr mode)" do
    {:ok, flow, _} = Flow.start(@quiz, "ivr") |> Flow.step()
    step = flow |> Flow.step(Flow.Message.reply("8"))
    assert {:ok, %Flow{}, %{stores: stores, prompts: prompts}} = step
    assert stores == %{"Smokes" => "Yes"}
    assert prompts == [%{"text" => "Do you exercise? Press 1 for YES, 2 for NO", "audio_source" => "tts"}]
  end

  test "next step with store, case insensitive, strip space" do
    {:ok, flow, _} = Flow.start(@quiz, "sms") |> Flow.step()
    step = flow |> Flow.step(Flow.Message.reply(" y "))
    assert {:ok, %Flow{}, %{stores: stores, prompts: prompts}} = step
    assert stores == %{"Smokes" => "Yes"}
    assert prompts == ["Do you exercise? Reply 1 for YES, 2 for NO"]
  end

  test "last step" do
    flow = Flow.start(@quiz, "sms")
    {:ok, flow, _} = flow |> Flow.step()
    {:ok, flow, _} = flow |> Flow.step(Flow.Message.reply("Y"))
    {:ok, flow, _} = flow |> Flow.step(Flow.Message.reply("N"))
    {:ok, flow, _} = flow |> Flow.step(Flow.Message.reply("99"))
    step = flow |> Flow.step(Flow.Message.reply("11"))
    assert {:end, _} = step
  end

  def init_quiz_and_send_response response do
    {:ok, flow, _} =
      build(:questionnaire, steps: @skip_logic)
      |> Flow.start("sms")
      |> Flow.step
    flow |> Flow.step(Flow.Message.reply(response))
  end

  # skip logic
  test "when skip_logic is end it ends the flow" do
    result = init_quiz_and_send_response("Y")

    assert {:end, _} = result
  end

  test "when skip_logic is null it continues with next step" do
    result = init_quiz_and_send_response("N")

    assert {:ok, _, _} = result
  end

  test "when skip_logic is not present continues with next step" do
    result = init_quiz_and_send_response("M")

    assert {:ok, _, _} = result
  end

  test "when skip_logic is a valid id jumps to the specified id" do
    {:ok, flow, _} = init_quiz_and_send_response("S")

    assert flow.current_step == 3
  end

  describe "numeric steps" do
    test "when value is in a middle range it finds it" do
      {:ok, flow, _} = init_quiz_and_send_response("S")
      result = flow |> Flow.step(Flow.Message.reply("50"))

      assert {:end, _} = result
    end

    test "when value is in the first range and it has no min value it finds it" do
      {:ok, flow, _} = init_quiz_and_send_response("S")
      result = flow |> Flow.step(Flow.Message.reply("-10"))

      assert {:end, _} = result
    end

    test "when value is in the last range and it has no max value it finds it" do
      {:ok, flow, _} = init_quiz_and_send_response("S")
      result = flow |> Flow.step(Flow.Message.reply("999"))

      assert {:end, _} = result
    end
  end

  describe "when skip_logic is an invalid id" do

    test "when it doesn't exist raises" do
      assert_raise RuntimeError, fn ->
        init_quiz_and_send_response("A")
      end
    end

    test "when the step is previous raises" do
      {:ok, flow, _} = init_quiz_and_send_response("M")

      assert_raise RuntimeError, fn ->
        flow
        |> Flow.step(Flow.Message.reply("Y"))
      end
    end

  end

  describe "multiple choice" do
    test "continues with next question when the reply isn't between the choices"
      do
      {:ok, flow, _} = Flow.start(@quiz, "sms") |> Flow.step()
      result = flow |> Flow.step(Flow.Message.reply("INVALID CHOICE"))

      assert {:ok, _, flow_reply} = result
      assert Enum.at(flow_reply.prompts, 0) == "Do you exercise? Reply 1 for YES, 2 for NO"
    end
  end

end
