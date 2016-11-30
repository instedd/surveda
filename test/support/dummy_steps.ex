defmodule Ask.StepBuilder do
  def multiple_choice_step(id: id, title: title, prompt: prompt, store: store, choices: choices) do
    %{
      "id" => id,
      "type" => "multiple-choice",
      "title" => title,
      "prompt" => prompt,
      "store" => store,
      "choices" => choices
    }
  end

  def numeric_step(id: id, title: title, prompt: prompt, store: store) do
    %{
      "id" => id,
      "type" => "numeric",
      "title" => title,
      "prompt" => prompt,
      "store" => store,
    }
  end

  def prompt(sms: sms) do
    %{
      "en" => %{
        "sms" => sms
      }
    }
  end

  def prompt(ivr: ivr) do
    %{
      "en" => %{
        "ivr" => ivr
      }
    }
  end

  def prompt(sms: sms, ivr: ivr) do
    %{
      "en" => %{
        "sms" => sms,
        "ivr" => ivr
      }
    }
  end

  def sms_prompt(prompt) do
    prompt
  end

  def tts_prompt(text) do
    %{
      "text" => text,
      "audio_source" => "tts"
    }
  end

  def audio_prompt(uuid: uuid, text: text) do
    %{
      "text" => text,
      "audio_id" => uuid,
      "audio_source" => "upload"
    }
  end

  def choice(value: value, responses: responses) do
    %{
      "value" => value,
      "responses" => responses
    }
  end

  def choice(value: value, responses: responses, skip_logic: skip_logic) do
    %{
      "value" => value,
      "responses" => responses,
      "skip_logic" => skip_logic
    }
  end

  def responses(sms: sms, ivr: ivr) do
    %{
      "en" => %{
        "sms" => sms,
        "ivr" => ivr
      }
    }
  end
end

defmodule Ask.DummySteps do
  import Ask.StepBuilder
  defmacro __using__(_) do
    quote do
      @dummy_steps [
        multiple_choice_step(
          id: Ecto.UUID.generate,
          title: "Do you smoke?",
          prompt: prompt(
            sms: sms_prompt("Do you smoke? Reply 1 for YES, 2 for NO"),
            ivr: tts_prompt("Do you smoke? Press 8 for YES, 9 for NO")
          ),
          store: "Smokes",
          choices: [
            choice(value: "Yes", responses: responses(sms: ["Yes", "Y", "1"], ivr: ["8"])),
            choice(value: "No", responses: responses(sms: ["No", "N", "2"], ivr: ["9"]))
          ]
        ),
        multiple_choice_step(
          id: Ecto.UUID.generate,
          title: "Do you exercise",
          prompt: prompt(
            sms: sms_prompt("Do you exercise? Reply 1 for YES, 2 for NO"),
            ivr: tts_prompt("Do you exercise? Press 1 for YES, 2 for NO")
          ),
          store: "Exercises",
          choices: [
            choice(value: "Yes", responses: responses(sms: ["Yes", "Y", "1"], ivr: ["1"])),
            choice(value: "No", responses: responses(sms: ["No", "N", "2"], ivr: ["2"]))
          ]
        ),
        numeric_step(
          id: Ecto.UUID.generate,
          title: "Which is the second perfect number?",
          prompt: prompt(sms: sms_prompt("Which is the second perfect number??")),
          store: "Perfect Number"
        )
      ]

      @skip_logic [
        multiple_choice_step(
          id: "aaa",
          title: "Do you smoke?",
          prompt: prompt(
            sms: sms_prompt("Do you smoke? Reply 1 for YES, 2 for NO, 3 for MAYBE, 4 for SOMETIMES, 5 for ALWAYS")
          ),
          store: "Smokes",
          choices: [
            choice(value: "Yes", responses: responses(sms: ["Yes", "Y", "1"], ivr: ["1"]), skip_logic: "end"),
            choice(value: "No", responses: responses(sms: ["No", "N", "2"], ivr: ["2"]), skip_logic: nil),
            choice(value: "Maybe", responses: responses(sms: ["Maybe", "M", "3"], ivr: ["3"])),
            choice(value: "Sometimes", responses: responses(sms: ["Sometimes", "S", "4"], ivr: ["4"]), skip_logic: "ccc"),
            choice(value: "ALWAYS", responses: responses(sms: ["Always", "A", "5"], ivr: ["5"]), skip_logic: "undefined_id")
          ]
        ),
        multiple_choice_step(
          id: "bbb",
          title: "Do you exercise?",
          prompt: prompt(
            sms: sms_prompt("Do you exercise? Reply 1 for YES, 2 for NO")
          ),
          store: "Exercises",
          choices: [
            choice(value: "Yes", responses: responses(sms: ["Yes", "Y", "1"], ivr: ["1"]), skip_logic: "aaa"),
            choice(value: "No", responses: responses(sms: ["No", "N", "2"], ivr: ["2"]))
          ]
        ),
        multiple_choice_step(
          id: "ccc",
          title: "Is this questionnaire refreshing?",
          prompt: prompt(
            sms: sms_prompt("Is this questionnaire refreshing? Reply 1 for YES, 2 for NO, 3 for MAYBE")
          ),
          store: "Refresh",
          choices: [
            choice(value: "Yes", responses: responses(sms: ["Yes", "Y", "1"], ivr: ["1"])),
            choice(value: "No", responses: responses(sms: ["No", "N", "2"], ivr: ["2"]))
          ]
        )
      ]
    end
  end
end
