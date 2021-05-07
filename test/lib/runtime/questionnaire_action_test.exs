defmodule Ask.Runtime.QuestionnaireExportTest do
  use Ask.ModelCase
  alias Ask.Questionnaire
  alias Ask.Runtime.{QuestionnaireExport, CleanI18n}

  describe "Ask.Runtime.QuestionnaireExport/1" do
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

    @sms_simple_choice %{
      "value" => "My SMS response 1",
      "skip_logic" => nil,
      "responses" => %{
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
    }

    @ivr_simple_choice %{
      "value" => "My IVR response 1",
      "skip_logic" => nil,
      "responses" => %{
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
    }

    @mobileweb_simple_choice %{
      "value" => "My MW response 1",
      "skip_logic" => nil,
      "responses" => %{
        "sms" => %{
          "en" => []
        },
        "mobileweb" => %{
          "en" => "1"
        },
        "ivr" => []
      }
    }

    @sms_simple_choice_step Map.merge(
                              @simple_choice_step,
                              %{
                                "prompt" => @sms_question_prompt,
                                "choices" => [@sms_simple_choice]
                              }
                            )

    @sms_multilingual_choice_step Map.merge(
                                    @simple_choice_step,
                                    %{
                                      "prompt" => @sms_multilingual_question_prompt,
                                      "choices" => []
                                    }
                                  )

    @sms_monolingual_choice_step Map.merge(
                                   @sms_simple_choice_step,
                                   %{
                                     "prompt" => @sms_question_prompt,
                                     "choices" => []
                                   }
                                 )

    @ivr_simple_choice_step Map.merge(
                              @simple_choice_step,
                              %{
                                "prompt" => @ivr_question_prompt,
                                "choices" => [@ivr_simple_choice]
                              }
                            )

    @mobileweb_simple_choice_step Map.merge(
                                    @simple_choice_step,
                                    %{
                                      "prompt" => @mobileweb_question_prompt,
                                      "choices" => [@mobileweb_simple_choice]
                                    }
                                  )

    @ivr_audio_simple_choice_step Map.merge(
                                    @simple_choice_step,
                                    %{
                                      "prompt" => @ivr_audio_question_prompt,
                                      "choices" => [@ivr_simple_choice]
                                    }
                                  )

    @sms_simple_quiz Map.merge(
                       @sms_empty_quiz,
                       %{
                         name: @quiz_title,
                         settings: @sms_simple_quiz_settings,
                         steps: [
                           @sms_simple_choice_step
                         ]
                       }
                     )

    @ivr_simple_quiz Map.merge(
                       @ivr_empty_quiz,
                       %{
                         name: @quiz_title,
                         settings: @ivr_simple_quiz_settings,
                         steps: [
                           @ivr_simple_choice_step
                         ]
                       }
                     )

    @mobileweb_simple_quiz Map.merge(
                             @mobileweb_empty_quiz,
                             %{
                               name: @quiz_title,
                               settings: @mobileweb_simple_quiz_settings,
                               steps: [
                                 @mobileweb_simple_choice_step
                               ]
                             }
                           )

    @ivr_audio_simple_quiz Map.merge(
                             @ivr_empty_quiz,
                             %{
                               name: @quiz_title,
                               settings: @ivr_simple_quiz_settings,
                               steps: [
                                 @ivr_audio_simple_choice_step
                               ]
                             }
                           )

    @sms_multilingual_quiz Map.merge(
                             @sms_empty_quiz,
                             %{
                               name: @quiz_title,
                               settings: @sms_simple_quiz_settings,
                               steps: [
                                 @sms_multilingual_choice_step
                               ],
                               languages: [
                                 "en",
                                 "es"
                               ]
                             }
                           )

    @deleted_language_simple_quiz Map.merge(
                                    @sms_multilingual_quiz,
                                    %{
                                      steps: [
                                        @sms_multilingual_choice_step
                                      ],
                                      languages: [
                                        "en"
                                      ]
                                    }
                                  )

    @deleted_language_simple_quiz_export Map.merge(
                                           @deleted_language_simple_quiz,
                                           %{
                                             steps: [
                                               @sms_monolingual_choice_step
                                             ]
                                           }
                                         )

    test "SMS - exports an empty questionnaire" do
      sms_empty_quiz = Map.merge(%Questionnaire{}, @sms_empty_quiz)

      sms_empty_quiz_export = QuestionnaireExport.export(sms_empty_quiz)

      assert sms_empty_quiz_export == %{
               manifest: @sms_empty_quiz,
               audio_ids: []
             }
    end

    test "SMS - exports a simple questionnaire" do
      sms_simple_quiz = Map.merge(%Questionnaire{}, @sms_simple_quiz)

      simple_quiz_export = QuestionnaireExport.export(sms_simple_quiz)

      assert simple_quiz_export == %{
               manifest: @sms_simple_quiz,
               audio_ids: []
             }
    end

    test "IVR - exports a simple questionnaire" do
      ivr_simple_quiz = Map.merge(%Questionnaire{}, @ivr_simple_quiz)

      ivr_simple_quiz_export = QuestionnaireExport.export(ivr_simple_quiz)

      assert ivr_simple_quiz_export == %{
               manifest: @ivr_simple_quiz,
               audio_ids: []
             }
    end

    test "IVR - exports a simple questionnaire with audios" do
      ivr_audio_simple_quiz = Map.merge(%Questionnaire{}, @ivr_audio_simple_quiz)

      ivr_audio_simple_quiz_export = QuestionnaireExport.export(ivr_audio_simple_quiz)

      assert ivr_audio_simple_quiz_export == %{
               manifest: @ivr_audio_simple_quiz,
               audio_ids: [@ivr_audio_id]
             }
    end

    test "Mobile Web - exports a simple questionnaire" do
      mobileweb_simple_quiz = Map.merge(%Questionnaire{}, @mobileweb_simple_quiz)

      mobileweb_simple_quiz_export = QuestionnaireExport.export(mobileweb_simple_quiz)

      assert mobileweb_simple_quiz_export == %{
               manifest: @mobileweb_simple_quiz,
               audio_ids: []
             }
    end

    test "SMS - exports a multilingual questionnaire" do
      sms_multilingual_quiz = Map.merge(%Questionnaire{}, @sms_multilingual_quiz)

      sms_multilingual_quiz_export = QuestionnaireExport.export(sms_multilingual_quiz)

      assert sms_multilingual_quiz_export == %{
               manifest: @sms_multilingual_quiz,
               audio_ids: []
             }
    end

    test "SMS - exports a deleted language simple questionnaire" do
      deleted_language_simple_quiz = Map.merge(%Questionnaire{}, @deleted_language_simple_quiz)

      deleted_language_simple_quiz_export =
        QuestionnaireExport.export(deleted_language_simple_quiz)

      assert deleted_language_simple_quiz_export == %{
               manifest: @deleted_language_simple_quiz_export,
               audio_ids: []
             }
    end
  end

  describe "QuestionnaireExport.clean_i18n_quiz/1" do
    test "doesn't change a quiz with no deleted languages" do
      quiz = insert(:questionnaire, languages: ["en"])

      clean = QuestionnaireExport.clean_i18n_quiz(quiz)

      assert clean == quiz
    end

    test "works when quota_completed_steps is nil" do
      quiz = insert(:questionnaire, languages: ["en"], quota_completed_steps: nil)

      clean = QuestionnaireExport.clean_i18n_quiz(quiz)

      assert clean == quiz
    end
  end

  describe "CleanI18n.clean/3" do
    test "cleans a base case" do
      entity = %{"en" => "foo", "es" => "bar"}

      clean = CleanI18n.clean(entity, ["en"], "")

      assert clean == %{"en" => "foo"}
    end

    test "cleans every map element" do
      entity = %{"bar" => %{"en" => "foo", "es" => "bar"}}

      clean = CleanI18n.clean(entity, ["en"], ".[]")

      assert clean == %{"bar" => %{"en" => "foo"}}
    end

    test "cleans every list element" do
      entity = [%{"en" => "foo", "es" => "bar"}]

      clean = CleanI18n.clean(entity, ["en"], ".[]")

      assert clean == [%{"en" => "foo"}]
    end

    test "cleans the requested key of a map" do
      entity = %{"a" => %{"en" => "foo", "es" => "bar"}, "b" => %{"en" => "foo", "es" => "bar"}}

      clean = CleanI18n.clean(entity, ["en"], ".a")

      assert clean == %{"a" => %{"en" => "foo"}, "b" => %{"en" => "foo", "es" => "bar"}}
    end

    test "doesn't crash when the content of the requested key isn't a map" do
      entity = %{"foo" => "bar"}

      clean = CleanI18n.clean(entity, ["baz"], ".foo")

      assert clean == %{"foo" => "bar"}
    end

    test "cleans choices (when the content of one of the requested keys isn't a map)" do
      # A real case cut that was making it crash.
      # What was making it crash: `"ivr" => []`. Because [] isn't a map.
      entity = [
        %{
          "choices" => [
            %{
              "responses" => %{"ivr" => [], "mobileweb" => %{"en" => "foo", "es" => "bar"}}
            }
          ]
        }
      ]

      clean = CleanI18n.clean(entity, ["en"], ".[].choices.[].responses.[]")

      assert clean == [
               %{
                 "choices" => [
                   %{
                     "responses" => %{"ivr" => [], "mobileweb" => %{"en" => "foo"}}
                   }
                 ]
               }
             ]
    end
  end
end
