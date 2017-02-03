defmodule Ask.FlowTest do
  use ExUnit.Case
  use Ask.DummySteps
  import Ask.Factory
  alias Ask.Runtime.Flow

  @quiz build(:questionnaire, steps: @dummy_steps)

  test "start" do
    flow = Flow.start(@quiz, "sms")
    assert %Flow{language: "en"} = flow
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

  test "retry step (sms mode)" do
    {:ok, flow, _} = Flow.start(@quiz, "sms") |> Flow.step()
    step = flow |> Flow.step(Flow.Message.reply("x"))
    assert {:ok, %Flow{}, %{prompts: prompts}} = step
    assert prompts == [
      "You have entered an invalid answer",
      "Do you smoke? Reply 1 for YES, 2 for NO"
    ]
  end

  test "retry step (ivr mode)" do
    {:ok, flow, _} = Flow.start(@quiz, "ivr") |> Flow.step()
    step = flow |> Flow.step(Flow.Message.reply("0"))
    assert {:ok, %Flow{}, %{prompts: prompts}} = step
    assert prompts == [
      %{"text" => "You have entered an invalid answer (ivr)", "audio_source" => "tts"},
      %{"text" => "Do you smoke? Press 8 for YES, 9 for NO", "audio_source" => "tts"}
    ]
  end

  test "retry step up to 3 times (sms mode)" do
    {:ok, flow, _} = Flow.start(@quiz, "sms") |> Flow.step()
    step = flow |> Flow.step(Flow.Message.reply("x"))
    {:ok, flow, %{prompts: prompts}} = step

    assert flow.retries == 1
    assert prompts == [
      "You have entered an invalid answer",
      "Do you smoke? Reply 1 for YES, 2 for NO"
    ]

    step = flow |> Flow.step(Flow.Message.reply("x"))
    {:ok, flow, %{prompts: prompts}} = step

    assert flow.retries == 2
    assert prompts == [
      "You have entered an invalid answer",
      "Do you smoke? Reply 1 for YES, 2 for NO"
    ]

    step = flow |> Flow.step(Flow.Message.reply("x"))

    assert {:end, _} = step
  end

  test "retry step 2 times, then valid answer, then retry 3 times (ivr mode)" do
    {:ok, flow, _} = Flow.start(@quiz, "ivr") |> Flow.step()
    step = flow |> Flow.step(Flow.Message.reply("0"))

    assert {:ok, flow, %{prompts: prompts}} = step
    assert flow.retries == 1
    assert prompts == [
      %{"text" => "You have entered an invalid answer (ivr)", "audio_source" => "tts"},
      %{"text" => "Do you smoke? Press 8 for YES, 9 for NO", "audio_source" => "tts"}
    ]

    step = flow |> Flow.step(Flow.Message.reply("8"))

    assert {:ok, flow, %{stores: stores, prompts: prompts}} = step
    assert flow.retries == 0
    assert stores == %{"Smokes" => "Yes"}
    assert prompts == [%{"text" => "Do you exercise? Press 1 for YES, 2 for NO", "audio_source" => "tts"}]

    step = flow |> Flow.step(Flow.Message.reply("8"))

    assert {:ok, flow, %{prompts: prompts}} = step
    assert flow.retries == 1
    assert prompts == [
      %{"text" => "You have entered an invalid answer (ivr)", "audio_source" => "tts"},
      %{"text" => "Do you exercise? Press 1 for YES, 2 for NO", "audio_source" => "tts"}
    ]

    step = flow |> Flow.step(Flow.Message.reply("8"))

    assert {:ok, flow, %{prompts: prompts}} = step
    assert flow.retries == 2
    assert prompts == [
      %{"text" => "You have entered an invalid answer (ivr)", "audio_source" => "tts"},
      %{"text" => "Do you exercise? Press 1 for YES, 2 for NO", "audio_source" => "tts"}
    ]

    step = flow |> Flow.step(Flow.Message.reply("8"))

    assert {:end, _} = step
  end

  test "no response is considered an invalid answer and consumes one retry" do
    {:ok, flow, _} = Flow.start(@quiz, "ivr") |> Flow.step()
    step = flow |> Flow.step(Flow.Message.reply(nil))

    assert {:ok, %Flow{retries: 1}, %{prompts: prompts}} = step
    assert prompts == [
      %{"text" => "You have entered an invalid answer (ivr)", "audio_source" => "tts"},
      %{"text" => "Do you smoke? Press 8 for YES, 9 for NO", "audio_source" => "tts"}
    ]
  end

  test "* is considered a valid answer and will reset retries" do
    {:ok, flow, _} = Flow.start(@quiz, "ivr") |> Flow.step()
    step = flow |> Flow.step(Flow.Message.reply(nil))
    assert {:ok, %Flow{retries: 1}, _} = step
    step = flow |> Flow.step(Flow.Message.reply("*"))
    assert {:ok, %Flow{retries: 0}, %{prompts: prompts}} = step
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

  describe "skip question" do
    test "numeric step continues with next question when skip question key is pressed" do
      {:ok, flow, _} = init_quiz_and_send_response("S")
      result = flow |> Flow.step(Flow.Message.reply("*"))

      assert {:ok, _, flow_reply} = result
      assert Enum.at(flow_reply.prompts, 0) == "Is this the last question?"
    end

    test "multiple choice step continues with next question when skip question key is pressed" do
      {:ok, flow, _} = Flow.start(@quiz, "sms") |> Flow.step()
      result = flow |> Flow.step(Flow.Message.reply("*"))

      assert {:ok, _, flow_reply} = result
      assert Enum.at(flow_reply.prompts, 0) == "Do you exercise? Reply 1 for YES, 2 for NO"
    end
  end

  test "language selection step" do
    steps = @dummy_steps
    languageStep = %{
      "id" => "1234-5678",
      "type" => "language-selection",
      "title" => "Language selection",
      "store" => "",
      "prompt" => %{
        "sms" => "1 for English, 2 for Spanish",
        "ivr" => %{
          "text" => "1 para ingles, 2 para español",
          "audioSource" => "tts",
        }
      },
      "language_choices" => [nil, "en", "es"],
    }
    steps = [languageStep | steps]
    quiz = build(:questionnaire, steps: steps)

    flow = Flow.start(quiz, "sms")
    assert flow.language == "en"

    step = flow |> Flow.step
    assert {:ok, flow, %{prompts: prompts}} = step

    assert prompts == ["1 for English, 2 for Spanish"]

    step = flow |> Flow.step(Flow.Message.reply("2"))
    assert {:ok, flow, %{prompts: prompts}} = step

    assert flow.language == "es"
    assert prompts == ["Do you smoke? Reply 1 for YES, 2 for NO (Spanish)"]
  end

  describe "explanation steps" do
    test "adds previous explanation steps to prompts" do
      quiz = build(:questionnaire, steps: @explanation_steps_minimal)
      flow = Flow.start(quiz, "sms")
      flow_state = flow |> Flow.step

      assert {:ok, flow, %{prompts: prompts}} = flow_state

      assert prompts == ["Is this the last question?", "Do you exercise? Reply 1 for YES, 2 for NO"]
      assert flow.current_step == 1
    end

    test "ends but keeps the prompts" do
      quiz = build(:questionnaire, steps: @only_explanation_steps)
      flow = Flow.start(quiz, "sms")
      flow_state = flow |> Flow.step

      assert {:end, %{prompts: prompts}} = flow_state

      assert prompts == ["Is this the last question?"]
    end
  end

  describe "flag steps" do
    test "flag steps and send prompts" do
      quiz = build(:questionnaire, steps: @flag_steps)
      flow = Flow.start(quiz, "sms")
      flow_state = flow |> Flow.step

      assert {:ok, flow, %{prompts: prompts, disposition: "partial"}} = flow_state

      assert prompts == ["Do you exercise? Reply 1 for YES, 2 for NO"]
      assert flow.current_step == 1
    end

    test "ending keeps the last flag" do
      quiz = build(:questionnaire, steps: @only_flag_steps)
      flow = Flow.start(quiz, "sms")
      flow_state = flow |> Flow.step
      assert {:end, %{disposition: "partial"}} = flow_state
    end
  end
end
