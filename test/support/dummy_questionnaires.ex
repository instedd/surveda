defmodule Ask.DummyQuestionnaireBuilder do
  alias Ask.Questionnaire

  def simple_choice(response) do
    %{
      "value" => "My response 1",
      "skip_logic" => nil,
      "responses" => response
    }
  end

  def section_with_step(step) do
    %{
      "type" => "section",
      "title" => "",
      "steps" => [
        step
      ],
      "randomize" => false,
      "id" => "e7493b26-b589-432d-bea3-e395d8394339"
    }
  end

  def build_quiz(quiz, options \\ []) do
    steps = Keyword.get(options, :steps)
    languages = Keyword.get(options, :languages)
    settings = Keyword.get(options, :settings)
    name = Keyword.get(options, :name)

    quiz = if steps, do: Map.put(quiz, :steps, steps), else: quiz
    quiz = if languages, do: Map.put(quiz, :languages, languages), else: quiz
    quiz = if settings, do: Map.put(quiz, :settings, settings), else: quiz
    quiz = if name, do: Map.put(quiz, :name, name), else: quiz

    quiz
  end

  def build_step(step, options \\ []) do
    prompt = Keyword.get(options, :prompt)
    choices = Keyword.get(options, :choices)

    step = if prompt, do: Map.put(step, "prompt", prompt), else: step
    step = if prompt, do: Map.put(step, "choices", choices), else: step

    step
  end

  def modelize_quiz(quiz) do
    Map.merge(%Questionnaire{}, quiz)
  end

  def build_expected_export(quiz, audio_ids \\ []) do
    %{
      manifest: quiz,
      audio_ids: audio_ids
    }
  end
end

defmodule Ask.DummyQuestionnaires do
  import Ask.DummyQuestionnaireBuilder

  defmacro __using__(_) do
    quote do
      @quiz_title "My questionnaire title"

      @empty_step %{
        "type" => "multiple-choice",
        "title" => "",
        "store" => "",
        "prompt" => %{
          "en" => %{
            "sms" => "",
            "mobileweb" => "",
            "ivr" => %{
              "text" => "",
              "audio_source" => "tts"
            }
          }
        },
        "id" => "e7590b58-5adb-48d1-a5db-4a118418ea88",
        "choices" => []
      }

      @empty_quiz %{
        steps: [@empty_step],
        settings: %{},
        quota_completed_steps: nil,
        partial_relevant_config: nil,
        name: nil,
        languages: [
          "en"
        ],
        default_language: "en"
      }

      @sms_empty_quiz Map.put(@empty_quiz, :modes, ["sms"])
      @ivr_empty_quiz Map.put(@empty_quiz, :modes, ["ivr"])
      @mobileweb_empty_quiz Map.put(@empty_quiz, :modes, ["mobileweb"])

      @sms_simple_quiz_settings %{
        "thank_you_message" => %{
          "en" => %{
            "sms" => "My thank you message"
          }
        },
        "error_message" => %{
          "en" => %{
            "sms" => "My error message"
          }
        }
      }

      @ivr_simple_quiz_settings %{
        "error_message" => %{
          "en" => %{"ivr" => %{"audio_source" => "tts", "text" => "My IVR error message"}}
        },
        "thank_you_message" => %{
          "en" => %{"ivr" => %{"audio_source" => "tts", "text" => "My IVR thank you message"}}
        }
      }

      @mobileweb_simple_quiz_settings %{
        "title" => %{
          "en" => "My MW title"
        },
        "thank_you_message" => %{
          "en" => %{
            "mobileweb" => "<p>My MW thank you message</p>"
          }
        },
        "survey_already_taken_message" => %{
          "en" => "<p>My MW survey already taken message</p>"
        },
        "mobileweb_survey_is_over_message" => "<p>My MW survey is over message</p>",
        "mobileweb_sms_message" => "My MW SMS message",
        "mobileweb_intro_message" => "<p>My MW intro message</p>",
        "error_message" => %{
          "en" => %{
            "mobileweb" => "<p>My MW error message</p>"
          }
        }
      }

      @simple_choice_step %{
        "type" => "multiple-choice",
        "title" => "My question title",
        "store" => "My variable name",
        "id" => "0b11a399-9b81-4552-a603-7df50d52f991"
      }

      @sms_question_prompt %{
        "en" => %{
          "sms" => "My question prompt",
          "mobileweb" => "",
          "ivr" => %{
            "text" => "",
            "audio_source" => "tts"
          }
        }
      }

      @sms_multilingual_question_prompt Map.merge(
                                          @sms_question_prompt,
                                          %{
                                            "es" => %{
                                              "sms" => "Mi pregunta en español",
                                              "mobileweb" => "",
                                              "ivr" => %{
                                                "text" => "",
                                                "audio_source" => "tts"
                                              }
                                            }
                                          }
                                        )

      @ivr_question_prompt %{
        "en" => %{
          "ivr" => %{
            "audio_source" => "tts",
            "text" => "Foo"
          },
          "mobileweb" => "",
          "sms" => ""
        }
      }

      @mobileweb_question_prompt %{
        "en" => %{
          "sms" => "",
          "mobileweb" => "<p>My MW question prompt</p>",
          "ivr" => %{
            "text" => "",
            "audio_source" => "tts"
          }
        }
      }

      @ivr_audio_id "6fe2fac8-18bf-48f7-970c-204d2f3408b0"

      @ivr_audio_question_prompt %{
        "en" => %{
          "sms" => "",
          "mobileweb" => "",
          "ivr" => %{
            "text" => "",
            "audio_source" => "upload",
            "audio_id" => @ivr_audio_id
          }
        }
      }

      @sms_simple_response %{
        "sms" => %{
          "en" => [
            "1"
          ]
        },
        "mobileweb" => %{
          "en" => ""
        },
        "ivr" => []
      }

      @sms_simple_choice simple_choice(@sms_simple_response)

      @ivr_simple_response %{
        "sms" => %{
          "en" => []
        },
        "mobileweb" => %{
          "en" => ""
        },
        "ivr" => [
          "1"
        ]
      }

      @ivr_simple_choice simple_choice(@ivr_simple_response)

      @mobileweb_simple_response %{
        "sms" => %{
          "en" => []
        },
        "mobileweb" => %{
          "en" => "1"
        },
        "ivr" => []
      }

      @mobileweb_simple_choice simple_choice(@mobileweb_simple_response)

      @sms_simple_choice_step build_step(@simple_choice_step,
                                prompt: @sms_question_prompt,
                                choices: [@sms_simple_choice]
                              )

      @sms_multilingual_choice_step build_step(
                                      @simple_choice_step,
                                      prompt: @sms_multilingual_question_prompt,
                                      choices: []
                                    )

      @sms_monolingual_choice_step build_step(
                                     @sms_simple_choice_step,
                                     prompt: @sms_question_prompt,
                                     choices: []
                                   )

      @ivr_simple_choice_step build_step(
                                @simple_choice_step,
                                prompt: @ivr_question_prompt,
                                choices: [@ivr_simple_choice]
                              )

      @mobileweb_simple_choice_step build_step(
                                      @simple_choice_step,
                                      prompt: @mobileweb_question_prompt,
                                      choices: [@mobileweb_simple_choice]
                                    )

      @ivr_audio_simple_choice_step build_step(
                                      @simple_choice_step,
                                      prompt: @ivr_audio_question_prompt,
                                      choices: [@ivr_simple_choice]
                                    )

      @sms_multilingual_quiz build_quiz(@sms_empty_quiz,
                               name: @quiz_title,
                               settings: @sms_simple_quiz_settings,
                               steps: [
                                 @sms_multilingual_choice_step
                               ],
                               languages: [
                                 "en",
                                 "es"
                               ]
                             )

      @sms_deleted_language_simple_quiz build_quiz(@sms_multilingual_quiz,
                                          steps: [
                                            @sms_multilingual_choice_step
                                          ],
                                          languages: [
                                            "en"
                                          ]
                                        )
    end
  end
end
