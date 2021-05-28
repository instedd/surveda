defmodule Ask.Runtime.QuestionnaireExportTest do
  use Ask.ModelCase
  use Ask.DummyQuestionnaires
  import Ask.DummyQuestionnaireBuilder
  alias Ask.Runtime.{QuestionnaireExport, CleanI18n}

  describe "Ask.Runtime.QuestionnaireExport/1" do
    test "SMS - exports an empty questionnaire" do
      quiz = @sms_empty_quiz

      export_result =
        modelize_quiz(quiz)
        |> QuestionnaireExport.export()

      assert export_result == build_expected_export(quiz)
    end

    test "SMS - exports a simple questionnaire" do
      quiz =
        build_quiz(
          @sms_empty_quiz,
          name: @quiz_title,
          settings: @sms_simple_quiz_settings,
          steps: [
            @sms_simple_choice_step
          ]
        )

      export_result = modelize_quiz(quiz) |> QuestionnaireExport.export()

      assert export_result == build_expected_export(quiz)
    end

    test "IVR - exports a simple questionnaire" do
      quiz =
        build_quiz(
          @ivr_empty_quiz,
          name: @quiz_title,
          settings: @ivr_simple_quiz_settings,
          steps: [
            @ivr_simple_choice_step
          ]
        )

      export_result = modelize_quiz(quiz) |> QuestionnaireExport.export()

      assert export_result == build_expected_export(quiz)
    end

    test "IVR - exports a simple questionnaire with audios" do
      quiz =
        build_quiz(
          @ivr_empty_quiz,
          name: @quiz_title,
          settings: @ivr_simple_quiz_settings,
          steps: [
            @ivr_audio_simple_choice_step
          ]
        )

      export_result = modelize_quiz(quiz) |> QuestionnaireExport.export()

      assert export_result ==
               build_expected_export(quiz, [@ivr_audio_id])
    end

    test "IVR - exports a questionnaire with language selection step" do
      quiz =
        build_quiz(
          @ivr_empty_quiz,
          name: @quiz_title,
          settings: @ivr_simple_quiz_settings,
          steps: [
            @ivr_language_selection_step
          ]
        )

      export_result = modelize_quiz(quiz) |> QuestionnaireExport.export()

      assert export_result ==
               build_expected_export(quiz, [@ivr_audio_id])
    end



    test "Mobile Web - exports a simple questionnaire" do
      quiz =
        build_quiz(
          @mobileweb_empty_quiz,
          name: @quiz_title,
          settings: @mobileweb_simple_quiz_settings,
          steps: [
            @mobileweb_simple_choice_step
          ]
        )

      export_result = modelize_quiz(quiz) |> QuestionnaireExport.export()

      assert export_result ==
               build_expected_export(quiz)
    end

    test "SMS - exports a multilingual questionnaire" do
      quiz = @sms_multilingual_quiz

      export_result =
        modelize_quiz(quiz)
        |> QuestionnaireExport.export()

      assert export_result == build_expected_export(quiz)
    end

    test "SMS - exports a deleted language simple questionnaire" do
      quiz =
        build_quiz(
          @sms_multilingual_quiz,
          steps: [@sms_multilingual_choice_step],
          languages: ["en"]
        )
        |> modelize_quiz()

      export_result = QuestionnaireExport.export(quiz)

      expected_quiz =
        build_quiz(@sms_deleted_language_simple_quiz,
          steps: [@sms_monolingual_choice_step],
          languages: ["en"]
        )

      assert export_result == build_expected_export(expected_quiz)
    end

    test "SMS - exports a deleted language with section questionnaire" do
      quiz =
        build_quiz(
          @sms_multilingual_quiz,
          steps: [section_with_step(@sms_multilingual_choice_step)],
          languages: ["en"]
        )
        |> modelize_quiz()

      export_result = QuestionnaireExport.export(quiz)

      expected_quiz =
        build_quiz(@sms_deleted_language_simple_quiz,
          steps: [section_with_step(@sms_monolingual_choice_step)],
          languages: ["en"]
        )

      assert export_result == build_expected_export(expected_quiz)
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

    test "doesn't clean the language selection prompt" do
      step = %{
        "type" => "language-selection",
        "prompt" => %{"foo" => "bar"}
      }

      clean = CleanI18n.clean(step, ["baz"], ".prompt")

      assert clean == step
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
