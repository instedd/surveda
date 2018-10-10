defmodule Ask.StepBuilder do
  def language_selection_step(id: id, title: title, prompt: prompt, store: store, choices: choices) do
    %{
      "id" => id,
      "type" => "language-selection",
      "title" => title,
      "prompt" => prompt,
      "store" => store,
      "language_choices" => choices
    }
  end

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

  def numeric_step(id: id, title: title, prompt: prompt, store: store,
    skip_logic: skip_logic, alphabetical_answers: alphabetical_answers, refusal: refusal) do
    base = %{
      "id" => id,
      "type" => "numeric",
      "title" => title,
      "prompt" => prompt,
      "store" => store,
      "refusal" => refusal,
      "alphabetical_answers" => alphabetical_answers
    }
    Map.merge(base, skip_logic)
  end

  def explanation_step(id: id, title: title, prompt: prompt, skip_logic: skip_logic) do
    %{
      "id" => id,
      "type" => "explanation",
      "title" => title,
      "prompt" => prompt,
      "skip_logic" => skip_logic,
    }
  end

  def flag_step(id: id, title: title, disposition: disposition) do
    flag_step(id: id, title: title, disposition: disposition, skip_logic: nil)
  end

  def flag_step(id: id, title: title, disposition: disposition, skip_logic: skip_logic) do
    %{
      "id" => id,
      "type" => "flag",
      "title" => title,
      "disposition" => disposition,
      "skip_logic" => skip_logic,
    }
  end

  def section(id: id, title: title, randomize: randomize, steps: steps) do
    %{
      "id" => id,
      "type" => "section",
      "title" => title,
      "randomize" => randomize,
      "steps" => steps
    }
  end

  def prompt(sms: sms) do
    %{
      "en" => %{
        "sms" => sms
      },
      "es" => %{
        "sms" => "#{sms} (Spanish)"
      }
    }
  end

  def prompt(mobileweb: text) do
    %{
      "en" => %{
        "mobileweb" => text
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
      },
      "es" => %{
        "sms" => "#{sms} (Spanish)",
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
      "responses" => responses,
      "skip_logic" => nil
    }
  end

  def choice(value: value, responses: responses, skip_logic: skip_logic) do
    %{
      "value" => value,
      "responses" => responses,
      "skip_logic" => skip_logic
    }
  end

  def responses(mobileweb: responses) do
    %{
      "mobileweb" => %{
        "en" => responses
      }
    }
  end

  def responses(sms: sms, ivr: ivr) do
    %{
      "sms" => %{
        "en" => sms
      },
      "ivr" => ivr
    }
  end

  def default_numeric_skip_logic() do
    %{
      "min_value" => nil,
      "max_value" => nil,
      "ranges_delimiters" => "",
      "ranges" => [%{"from" => nil, "to" => nil, "skip_logic" => nil}]
    }
  end

  def numeric_skip_logic(min_value: min_value, max_value: max_value, ranges_delimiters:
    ranges_delimiters, ranges: ranges) do
    # froms =
    #   ranges_delimiters
    #   |> String.split(",")
    #   |> Enum.map(&String.to_integer/1)
    # tos =
    #   froms
    #   |> Enum.drop(1)
    #   |> Enum.map(fn(v) -> v-1 end)
    #   |> Enum.concat([max_value])
    # ranges = Enum.zip(froms, tos)
    %{
      "min_value" => min_value,
      "max_value" => max_value,
      "ranges_delimiters" => ranges_delimiters,
      "ranges" => ranges
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
          prompt: prompt(
            sms: sms_prompt("Which is the second perfect number??"),
            ivr: tts_prompt("Which is the second perfect number")
            ),
          store: "Perfect Number",
          skip_logic: default_numeric_skip_logic(),
          alphabetical_answers: false,
          refusal: nil
        ),
        numeric_step(
          id: Ecto.UUID.generate,
          title: "What's the number of this question?",
          prompt: prompt(
            sms: sms_prompt("What's the number of this question??"),
            ivr: tts_prompt("What's the number of this question")
            ),
          store: "Question",
          skip_logic: default_numeric_skip_logic(),
          alphabetical_answers: false,
          refusal: nil
        )
      ]

      @steps_with_duplicate_store [
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
        )
      ]

      @dummy_steps_with_flag [
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
        flag_step(
          id: "aaa",
          title: "Let there be rock",
          disposition: "interim partial"
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
        flag_step(
          id: "aaa",
          title: "Let there be rock",
          disposition: "completed"
        ),
        numeric_step(
          id: Ecto.UUID.generate,
          title: "Which is the second perfect number?",
          prompt: prompt(sms: sms_prompt("Which is the second perfect number??")),
          store: "Perfect Number",
          skip_logic: default_numeric_skip_logic(),
          alphabetical_answers: false,
          refusal: nil
        ),
        flag_step(
          id: "aaa",
          title: "Let there be rock",
          disposition: "completed"
        ),
        flag_step( # This step is here to make sure we ignore this change
          id: "aaa",
          title: "Let there be rock",
          disposition: "interim partial"
        ),
        numeric_step(
          id: Ecto.UUID.generate,
          title: "What's the number of this question?",
          prompt: prompt(sms: sms_prompt("What's the number of this question??")),
          store: "Question",
          skip_logic: default_numeric_skip_logic(),
          alphabetical_answers: false,
          refusal: nil
        )
      ]

      @skip_logic [
        multiple_choice_step(
          id: "aaa",
          title: "Do you smoke?",
          prompt: prompt(
            sms: sms_prompt("Do you smoke? Reply 1 for YES, 2 for NO, 3 for MAYBE, 4 for SOMETIMES, 5 for ALWAYS, 6 for I dont know")
          ),
          store: "Smokes",
          choices: [
            choice(value: "Yes", responses: responses(sms: ["Yes", "Y", "1"], ivr: ["1"]), skip_logic: "end"),
            choice(value: "No", responses: responses(sms: ["No", "N", "2"], ivr: ["2"]), skip_logic: nil),
            choice(value: "Maybe", responses: responses(sms: ["Maybe", "M", "3"], ivr: ["3"])),
            choice(value: "Sometimes", responses: responses(sms: ["Sometimes", "S", "4"], ivr: ["4"]), skip_logic: "ddd"),
            choice(value: "ALWAYS", responses: responses(sms: ["Always", "A", "5"], ivr: ["5"]), skip_logic: "undefined_id"),
            choice(value: "I don't know", responses: responses(sms: ["Dont know", "D", "6"], ivr: ["6"]), skip_logic: "")
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
        ),
        numeric_step(
          id: "ddd",
          title:
          "What is the probability that a number has more prime factors than the sum of its digits?",
          prompt: prompt(
            sms: sms_prompt("What is the probability that a number has more prime factors than the sum of its digits?")
          ),
          store: "Probability",
          skip_logic: numeric_skip_logic(min_value: 0, max_value: 100,
            ranges_delimiters: "25,75", ranges: [
                %{
                  "from" => nil,
                  "to" => 24,
                  "skip_logic" => "end"
                },
                %{
                  "from" => 25,
                  "to" => 74,
                  "skip_logic" => "end"
                },
                %{
                  "from" => 75,
                  "to" => nil,
                  "skip_logic" => "end"
                }
              ]
            ),
            alphabetical_answers: true,
            refusal: nil
          ),
          multiple_choice_step(
            id: "eee",
            title: "Is this the last question?",
            prompt: prompt(
              sms: sms_prompt("Is this the last question?")
            ),
            store: "Last",
            choices: [
              choice(value: "Yes", responses: responses(sms: ["Yes", "Y", "1"], ivr: ["1"])),
              choice(value: "No", responses: responses(sms: ["No", "N", "2"], ivr: ["2"]))
            ]
          )
      ]

      @explanation_steps_minimal [
        explanation_step(
          id: "aaa",
          title: "Let there be rock",
          prompt: prompt(
            sms: sms_prompt("Is this the last question?")
          ),
          skip_logic: nil
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
        )
      ]

      @only_explanation_steps [
        explanation_step(
          id: "aaa",
          title: "Let there be rock",
          prompt: prompt(
            sms: sms_prompt("Is this the last question?")
          ),
          skip_logic: nil
        )
      ]

      @flag_steps [
        flag_step(
          id: "aaa",
          title: "Let there be rock",
          disposition: "interim partial"
        ),
        multiple_choice_step(
          id: "bbb",
          title: "Do you exercise?",
          prompt: prompt(
            sms: sms_prompt("Do you exercise? Reply 1 for YES, 2 for NO")
          ),
          store: "Exercises",
          choices: [
            choice(value: "Yes", responses: responses(sms: ["Yes", "Y", "1"], ivr: ["1"])),
            choice(value: "No", responses: responses(sms: ["No", "N", "2"], ivr: ["2"]))
          ]
        ),
        multiple_choice_step(
          id: "eee",
          title: "Is this the last question?",
          prompt: prompt(
            sms: sms_prompt("Is this the last question?")
          ),
          store: "Last",
          choices: [
            choice(value: "Yes", responses: responses(sms: ["Yes", "Y", "1"], ivr: ["1"])),
            choice(value: "No", responses: responses(sms: ["No", "N", "2"], ivr: ["2"]))
          ]
        )
      ]

      @flag_step_after_multiple_choice [
        multiple_choice_step(
          id: "bbb",
          title: "Do you exercise?",
          prompt: prompt(
            sms: sms_prompt("Do you exercise? Reply 1 for YES, 2 for NO"),
            ivr: tts_prompt("Do you exercise? Reply 1 for YES, 2 for NO")
          ),
          store: "Exercises",
          choices: [
            choice(value: "Yes", responses: responses(sms: ["Yes", "Y", "1"], ivr: ["1"])),
            choice(value: "No", responses: responses(sms: ["No", "N", "2"], ivr: ["2"]))
          ]
        ),
        flag_step(
          id: "aaa",
          title: "Let there be rock",
          disposition: "interim partial"
        ),
        multiple_choice_step(
          id: "eee",
          title: "Is this the last question?",
          prompt: prompt(
            sms: sms_prompt("Is this the last question?"),
            ivr: tts_prompt("Is this the last question?")
          ),
          store: "Last",
          choices: [
            choice(value: "Yes", responses: responses(sms: ["Yes", "Y", "1"], ivr: ["1"])),
            choice(value: "No", responses: responses(sms: ["No", "N", "2"], ivr: ["2"]))
          ]
        )
      ]

      @flag_steps_ineligible_skip_logic [
        multiple_choice_step(
          id: "aaa",
          title: "Do you exercise?",
          prompt: prompt(
            sms: sms_prompt("Do you exercise? Reply 1 for YES, 2 for NO")
          ),
          store: "Exercises",
          choices: [
            choice(value: "Yes", responses: responses(sms: ["Yes", "Y", "1"], ivr: ["1"])),
            choice(value: "No", responses: responses(sms: ["No", "N", "2"], ivr: ["2"]))
          ]
        ),
        flag_step(
          id: "bbb",
          title: "Let there be rock",
          disposition: "ineligible"
        ),
        explanation_step(
          id: "ccc",
          title: "Bye",
          prompt: prompt(
            sms: sms_prompt("Good bye")
          ),
          skip_logic: "end"
        ),
      ]

      @flag_steps_refused_skip_logic [
        multiple_choice_step(
          id: "aaa",
          title: "Do you exercise?",
          prompt: prompt(
            sms: sms_prompt("Do you exercise? Reply 1 for YES, 2 for NO")
          ),
          store: "Exercises",
          choices: [
            choice(value: "Yes", responses: responses(sms: ["Yes", "Y", "1"], ivr: ["1"])),
            choice(value: "No", responses: responses(sms: ["No", "N", "2"], ivr: ["2"]))
          ]
        ),
        flag_step(
          id: "bbb",
          title: "Let there be rock",
          disposition: "refused"
        ),
        explanation_step(
          id: "ccc",
          title: "Bye",
          prompt: prompt(
            sms: sms_prompt("Good bye")
          ),
          skip_logic: "end"
        ),
      ]

      @flag_steps_partial_skip_logic [
        multiple_choice_step(
          id: "aaa",
          title: "Do you exercise?",
          prompt: prompt(
            sms: sms_prompt("Do you exercise? Reply 1 for YES, 2 for NO")
          ),
          store: "Exercises",
          choices: [
            choice(value: "Yes", responses: responses(sms: ["Yes", "Y", "1"], ivr: ["1"])),
            choice(value: "No", responses: responses(sms: ["No", "N", "2"], ivr: ["2"]))
          ]
        ),
        flag_step(
          id: "bbb",
          title: "Let there be rock",
          disposition: "interim partial"
        ),
        explanation_step(
          id: "ccc",
          title: "Bye",
          prompt: prompt(
            sms: sms_prompt("Good bye")
          ),
          skip_logic: "end"
        ),
      ]

      @partial_step [
        flag_step(
          id: "aaa",
          title: "Let there be rock",
          disposition: "interim partial"
        )
      ]

      @completed_step [
        flag_step(
          id: "b",
          title: "Let there be rock",
          disposition: "completed"
        )
      ]

      @ineligible_step [
        flag_step(
          id: "c",
          title: "Let there be rock",
          disposition: "ineligible"
        )
      ]

      @refused_step [
        flag_step(
          id: "s3",
          title: "Let there be rock",
          disposition: "refused"
        )
      ]

      @invalid_ineligible_after_partial_steps [
        flag_step(
          id: "aaa",
          title: "Let there be rock",
          disposition: "interim partial"
        ),
        multiple_choice_step(
          id: "bbb",
          title: "Do you exercise?",
          prompt: prompt(
            sms: sms_prompt("Do you exercise? Reply 1 for YES, 2 for NO")
          ),
          store: "Exercises",
          choices: [
            choice(value: "Yes", responses: responses(sms: ["Yes", "Y", "1"], ivr: ["1"])),
            choice(value: "No", responses: responses(sms: ["No", "N", "2"], ivr: ["2"]))
          ]
        ),
        flag_step(
          id: "aaa",
          title: "Let there be rock",
          disposition: "ineligible"
        ),
        multiple_choice_step(
          id: "eee",
          title: "Is this the last question?",
          prompt: prompt(
            sms: sms_prompt("Is this the last question?")
          ),
          store: "Last",
          choices: [
            choice(value: "Yes", responses: responses(sms: ["Yes", "Y", "1"], ivr: ["1"])),
            choice(value: "No", responses: responses(sms: ["No", "N", "2"], ivr: ["2"]))
          ]
        )
      ]

      @invalid_ineligible_after_completed_steps [
        flag_step(
          id: "aaa",
          title: "Let there be rock",
          disposition: "completed"
        ),
        multiple_choice_step(
          id: "bbb",
          title: "Do you exercise?",
          prompt: prompt(
            sms: sms_prompt("Do you exercise? Reply 1 for YES, 2 for NO")
          ),
          store: "Exercises",
          choices: [
            choice(value: "Yes", responses: responses(sms: ["Yes", "Y", "1"], ivr: ["1"])),
            choice(value: "No", responses: responses(sms: ["No", "N", "2"], ivr: ["2"]))
          ]
        ),
        flag_step(
          id: "aaa",
          title: "Let there be rock",
          disposition: "ineligible"
        ),
        multiple_choice_step(
          id: "eee",
          title: "Is this the last question?",
          prompt: prompt(
            sms: sms_prompt("Is this the last question?")
          ),
          store: "Last",
          choices: [
            choice(value: "Yes", responses: responses(sms: ["Yes", "Y", "1"], ivr: ["1"])),
            choice(value: "No", responses: responses(sms: ["No", "N", "2"], ivr: ["2"]))
          ]
        )
      ]

      @invalid_partial_after_ineligible_steps [
        flag_step(
          id: "aaa",
          title: "Let there be rock",
          disposition: "ineligible"
        ),
        multiple_choice_step(
          id: "bbb",
          title: "Do you exercise?",
          prompt: prompt(
            sms: sms_prompt("Do you exercise? Reply 1 for YES, 2 for NO")
          ),
          store: "Exercises",
          choices: [
            choice(value: "Yes", responses: responses(sms: ["Yes", "Y", "1"], ivr: ["1"])),
            choice(value: "No", responses: responses(sms: ["No", "N", "2"], ivr: ["2"]))
          ]
        ),
        flag_step(
          id: "aaa",
          title: "Let there be rock",
          disposition: "interim partial"
        ),
        multiple_choice_step(
          id: "eee",
          title: "Is this the last question?",
          prompt: prompt(
            sms: sms_prompt("Is this the last question?")
          ),
          store: "Last",
          choices: [
            choice(value: "Yes", responses: responses(sms: ["Yes", "Y", "1"], ivr: ["1"])),
            choice(value: "No", responses: responses(sms: ["No", "N", "2"], ivr: ["2"]))
          ]
        )
      ]

      @invalid_completed_after_ineligible_steps [
        flag_step(
          id: "aaa",
          title: "Let there be rock",
          disposition: "ineligible"
        ),
        multiple_choice_step(
          id: "bbb",
          title: "Do you exercise?",
          prompt: prompt(
            sms: sms_prompt("Do you exercise? Reply 1 for YES, 2 for NO")
          ),
          store: "Exercises",
          choices: [
            choice(value: "Yes", responses: responses(sms: ["Yes", "Y", "1"], ivr: ["1"])),
            choice(value: "No", responses: responses(sms: ["No", "N", "2"], ivr: ["2"]))
          ]
        ),
        flag_step(
          id: "aaa",
          title: "Let there be rock",
          disposition: "completed"
        ),
        multiple_choice_step(
          id: "eee",
          title: "Is this the last question?",
          prompt: prompt(
            sms: sms_prompt("Is this the last question?")
          ),
          store: "Last",
          choices: [
            choice(value: "Yes", responses: responses(sms: ["Yes", "Y", "1"], ivr: ["1"])),
            choice(value: "No", responses: responses(sms: ["No", "N", "2"], ivr: ["2"]))
          ]
        )
      ]

      @mobileweb_dummy_steps [
        explanation_step(
          id: "s1",
          title: "Let there be rock",
          prompt: prompt(
            mobileweb: sms_prompt("Welcome to the survey!")
          ),
          skip_logic: nil
        ),
        multiple_choice_step(
          id: "s2",
          title: "Do you smoke?",
          prompt: prompt(
            mobileweb: "Do you smoke?"
          ),
          store: "Smokes",
          choices: [
            choice(value: "Yes", responses: responses(mobileweb: "Yes")),
            choice(value: "No", responses: responses(mobileweb: "No"))
          ]
        ),
        flag_step(
          id: "s3",
          title: "Let there be rock",
          disposition: "interim partial"
        ),
        multiple_choice_step(
          id: "s4",
          title: "Do you exercise",
          prompt: prompt(
            mobileweb: "Do you exercise?"
          ),
          store: "Exercises",
          choices: [
            choice(value: "Yes", responses: responses(mobileweb: "Yes")),
            choice(value: "No", responses: responses(mobileweb: "No"))
          ]
        ),
        numeric_step(
          id: "s5",
          title: "Which is the second perfect number?",
          prompt: prompt(
            mobileweb: "Which is the second perfect number??"
            ),
          store: "Perfect Number",
          skip_logic: default_numeric_skip_logic(),
          alphabetical_answers: false,
          refusal: %{
            "enabled" => true,
            "responses" => %{
              "mobileweb" => %{
                "en" => "skip me",
              }
            },
            "skip_logic" => "end",
          }
        ),
        numeric_step(
          id: "s6",
          title: "What's the number of this question?",
          prompt: prompt(
            mobileweb: "What's the number of this question??"
            ),
          store: "Question",
          skip_logic: default_numeric_skip_logic(),
          alphabetical_answers: false,
          refusal: nil
        )
      ]

      @mobileweb_refusal_dummy_steps [
        explanation_step(
          id: "s1",
          title: "Let there be rock",
          prompt: prompt(
            mobileweb: sms_prompt("Welcome to the survey!")
          ),
          skip_logic: nil
        ),
        flag_step(
          id: "s3",
          title: "Let there be rock",
          disposition: "refused",
          skip_logic: "end"
        ),
      ]

      @one_section [
        section(
          id: "section 1",
          title: "First section",
          randomize: true,
          steps: @skip_logic
        )
      ]

      @three_sections [
        section(
          id: "section 1",
          title: "First section",
          randomize: false,
          steps: @skip_logic
        ),
        section(
          id: "section 2",
          title: "Second section",
          randomize: false,
          steps: @dummy_steps
        ),
        section(
          id: "section 3",
          title: "Third section",
          randomize: false,
          steps: @explanation_steps_minimal
        )
      ]

      @three_sections_random [
        section(
          id: "section 1",
          title: "First section",
          randomize: true,
          steps: @skip_logic
        ),
        section(
          id: "section 2",
          title: "Second section",
          randomize: false,
          steps: @dummy_steps
        ),
        section(
          id: "section 3",
          title: "Third section",
          randomize: true,
          steps: @dummy_steps_with_flag
        )
      ]

      @three_sections_all_random [
        section(
          id: "section 1",
          title: "First section",
          randomize: true,
          steps: @explanation_steps_minimal
        ),
        section(
          id: "section 2",
          title: "Second section",
          randomize: true,
          steps: @dummy_steps
        ),
        section(
          id: "section 3",
          title: "Third section",
          randomize: true,
          steps: @dummy_steps_with_flag
        )
      ]

      @three_sections_skip_logic [
        section(
          id: "section 1",
          title: "First section",
          randomize: false,
          steps: [
            multiple_choice_step(
              id: "aaa",
              title: "Do you want to end this section?",
              prompt: prompt(
                sms: sms_prompt("Do you want to end this section? Reply 1 for YES, 2 for NO")
              ),
              store: "end_section",
              choices: [
                choice(value: "Yes", responses: responses(sms: ["Yes", "Y", "1"], ivr: ["1"]), skip_logic: "end_section"),
                choice(value: "No", responses: responses(sms: ["No", "N", "2"], ivr: ["2"]), skip_logic: "ddd")
              ]
            )] ++ @skip_logic
        ),
        section(
          id: "section 2",
          title: "Second section",
          randomize: false,
          steps: @dummy_steps
        ),
        section(
          id: "section 3",
          title: "Third section",
          randomize: false,
          steps: @explanation_steps_minimal
        )
      ]
    end
  end
end
