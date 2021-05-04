defmodule Ask.Runtime.QuestionnaireExportTest do
  use Ask.ModelCase
  alias Ask.Questionnaire
  alias Ask.Runtime.{QuestionnaireExport, CleanI18n}

  describe "Ask.Runtime.QuestionnaireExport/1" do
    test "exports an empty questionnaire" do
      empty_quiz = Map.merge(%Questionnaire{}, empty_quiz())

      empty_quiz_export = QuestionnaireExport.export(empty_quiz)

      assert empty_quiz_export == %{
               manifest: empty_quiz(),
               audio_ids: []
             }
    end

    test "exports a simple questionnaire" do
      simple_quiz = Map.merge(%Questionnaire{}, simple_quiz())

      simple_quiz_export = QuestionnaireExport.export(simple_quiz)

      assert simple_quiz_export == %{
               manifest: simple_quiz(),
               audio_ids: []
             }
    end
  end

  defp empty_quiz() do
    %{
      steps: [empty_step()],
      settings: %{},
      quota_completed_steps: nil,
      partial_relevant_config: nil,
      name: nil,
      modes: [
        "sms"
      ],
      languages: [
        "en"
      ],
      default_language: "en"
    }
  end

  defp empty_step() do
    %{
      type: "multiple-choice",
      title: "",
      store: "",
      prompt: %{
        en: %{
          sms: "",
          mobileweb: "",
          ivr: %{
            text: "",
            audio_source: "tts"
          }
        }
      },
      id: "e7590b58-5adb-48d1-a5db-4a118418ea88",
      choices: []
    }
  end

  defp simple_quiz() do
    %{
      empty_quiz()
      | name: "My questionnaire title",
        settings: simple_quiz_settings(),
        steps: [
          simple_choice_step()
        ]
    }
  end

  defp simple_choice_step() do
    %{
      type: "multiple-choice",
      title: "My question title",
      store: "My variable name",
      prompt: %{
        en: %{
          sms: "My question prompt",
          mobileweb: "",
          ivr: %{
            text: "",
            audio_source: "tts"
          }
        }
      },
      id: "0b11a399-9b81-4552-a603-7df50d52f991",
      choices: []
    }
  end

  defp simple_quiz_settings() do
    %{
      thank_you_message: %{
        en: %{
          sms: "My thank you message"
        }
      },
      error_message: %{
        en: %{
          sms: "My error message"
        }
      }
    }
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
